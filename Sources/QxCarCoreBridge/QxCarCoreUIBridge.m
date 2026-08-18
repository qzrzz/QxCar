#import "include/QxCarCoreUIBridge.h"
#import <ImageIO/ImageIO.h>
#import <objc/runtime.h>
#import <objc/message.h>
#import <dlfcn.h>

typedef struct CGSVGDocument *CGSVGDocumentRef;
static void (*CGSVGDocumentWriteToURL_)(CGSVGDocumentRef, CFURLRef, CFDictionaryRef) = NULL;

@implementation QxCarCoreUIBridge

+ (BOOL)ensureFrameworksLoaded {
    static BOOL loaded = NO;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *coreUI = dlopen("/System/Library/PrivateFrameworks/CoreUI.framework/CoreUI", RTLD_NOW);
        void *coreSVG = dlopen("/System/Library/PrivateFrameworks/CoreSVG.framework/CoreSVG", RTLD_NOW);
        if (coreSVG) {
            CGSVGDocumentWriteToURL_ = (void (*)(CGSVGDocumentRef, CFURLRef, CFDictionaryRef))dlsym(coreSVG, "CGSVGDocumentWriteToURL");
        }
        loaded = (coreUI != NULL);
    });
    return loaded;
}

+ (nullable id)openCatalogWithPath:(NSString *)carPath error:(NSError **)error {
    [self ensureFrameworksLoaded];
    Class cuiCatalogClass = NSClassFromString(@"CUICatalog");
    if (!cuiCatalogClass) {
        if (error) {
            *error = [NSError errorWithDomain:@"com.qzrzz.qxcar"
                                         code:101
                                     userInfo:@{NSLocalizedDescriptionKey: @"未找到 CUICatalog 类，CoreUI 框架加载失败"}];
        }
        return nil;
    }

    NSURL *url = [NSURL fileURLWithPath:carPath];
    NSError *initError = nil;
    id catalog = [[cuiCatalogClass alloc] initWithURL:url error:&initError];
    if (!catalog && error) {
        *error = initError ?: [NSError errorWithDomain:@"com.qzrzz.qxcar"
                                                  code:102
                                              userInfo:@{NSLocalizedDescriptionKey: @"无法打开 Assets.car 文件"}];
    }
    return catalog;
}

+ (NSArray<NSString *> *)getIconStackNamesFromCatalog:(id)catalog {
    if (!catalog) return @[];
    NSMutableSet<NSString *> *stackNames = [NSMutableSet set];

    // 方式 1: enumerateNamedLookupsUsingBlock
    if ([catalog respondsToSelector:NSSelectorFromString(@"enumerateNamedLookupsUsingBlock:")]) {
        void (^block)(id) = ^(id lookup) {
            if (!lookup) return;
            SEL nameSel = NSSelectorFromString(@"name");
            if ([lookup respondsToSelector:nameSel]) {
                NSString *name = ((NSString *(*)(id, SEL))objc_msgSend)(lookup, nameSel);
                // 判断是否是 IconImageStack
                NSString *className = NSStringFromClass([lookup class]);
                if ([className containsString:@"Icon"] || [name hasPrefix:@"AppIcon"]) {
                    if (name.length > 0) [stackNames addObject:name];
                }
            }
        };
        ((void (*)(id, SEL, id))objc_msgSend)(catalog, NSSelectorFromString(@"enumerateNamedLookupsUsingBlock:"), block);
    }

    // 默认测试常见图标名称
    NSArray *commonNames = @[@"AppIcon", @"AppIconUpdated", @"Settings", @"AppIcon-iOS", @"AppIcon-macOS"];
    for (NSString *candidate in commonNames) {
        SEL stackSel = NSSelectorFromString(@"iconLayerStackWithName:scaleFactor:deviceIdiom:deviceSubtype:displayGamut:appearanceName:locale:");
        if ([catalog respondsToSelector:stackSel]) {
            id stack = ((id (*)(id, SEL, id, double, long long, unsigned long long, long long, id, id))objc_msgSend)(
                catalog, stackSel, candidate, 1.0, 0, 0, 0, nil, nil
            );
            if (stack) {
                [stackNames addObject:candidate];
            }
        }
    }

    return [stackNames.allObjects sortedArrayUsingSelector:@selector(compare:)];
}

+ (NSArray<NSString *> *)getAllImageNamesFromCatalog:(id)catalog {
    if (!catalog) return @[];
    if ([catalog respondsToSelector:NSSelectorFromString(@"allImageNames")]) {
        NSArray *names = ((NSArray *(*)(id, SEL))objc_msgSend)(catalog, NSSelectorFromString(@"allImageNames"));
        if ([names isKindOfClass:[NSArray class]]) {
            return names;
        }
    }
    return @[];
}

#pragma mark - Helper Functions

static NSString *safeFileName(NSString *n) {
    return [[n stringByReplacingOccurrencesOfString:@"/" withString:@"__"] stringByReplacingOccurrencesOfString:@" " withString:@"_"];
}

static id colorToJSON(CGColorRef c) {
    if (!c) return [NSNull null];
    CGColorSpaceRef cs = CGColorGetColorSpace(c);
    CFStringRef csName = cs ? CGColorSpaceCopyName(cs) : NULL;
    size_t n = CGColorGetNumberOfComponents(c);
    const CGFloat *comp = CGColorGetComponents(c);
    NSMutableArray *arr = [NSMutableArray array];
    for (size_t i = 0; i < n; i++) {
        [arr addObject:@(comp[i])];
    }
    NSString *nameStr = csName ? (__bridge_transfer NSString *)csName : @"?";
    return @{ @"colorspace": nameStr, @"components": arr };
}

static id getValueViaSelector(id obj, NSString *selName) {
    if (!obj) return nil;
    SEL s = NSSelectorFromString(selName);
    if (![obj respondsToSelector:s]) return nil;
    NSMethodSignature *sig = [obj methodSignatureForSelector:s];
    if (!sig) return nil;
    const char *rt = sig.methodReturnType;
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature:sig];
    inv.target = obj;
    inv.selector = s;
    [inv invoke];
    if (rt[0] == '@') {
        __unsafe_unretained id r;
        [inv getReturnValue:&r];
        return r;
    }
    if (rt[0] == 'd') { double d; [inv getReturnValue:&d]; return @(d); }
    if (rt[0] == 'f') { float f; [inv getReturnValue:&f]; return @(f); }
    if (rt[0] == 'i') { int i; [inv getReturnValue:&i]; return @(i); }
    if (rt[0] == 'q') { long long q; [inv getReturnValue:&q]; return @(q); }
    if (rt[0] == 'Q') { unsigned long long q; [inv getReturnValue:&q]; return @(q); }
    if (rt[0] == 'B' || rt[0] == 'c') { BOOL b; [inv getReturnValue:&b]; return @(b); }
    return nil;
}

+ (BOOL)saveCGImage:(CGImageRef)image toPath:(NSString *)path {
    if (!image || !path) return NO;
    NSURL *url = [NSURL fileURLWithPath:path];
    CGImageDestinationRef dest = CGImageDestinationCreateWithURL((__bridge CFURLRef)url, CFSTR("public.png"), 1, NULL);
    if (!dest) return NO;
    CGImageDestinationAddImage(dest, image, NULL);
    BOOL ok = CGImageDestinationFinalize(dest);
    CFRelease(dest);
    return ok;
}

static NSDictionary *dumpLayerNode(id layer, NSString *outDir, NSString *appearance) {
    if (!layer) return @{};
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"class"] = NSStringFromClass([layer class]);

    NSArray *properties = @[
        @"name", @"opacity", @"blendMode", @"blurStrength", @"hasLightingEffects",
        @"gradientOrColorName", @"fixedFrame", @"gathersSpecularByElement", @"hasSpecular",
        @"translucency", @"shadowStyle", @"shadowOpacity", @"renditionName", @"appearance",
        @"refractionStrength", @"refractionHeight", @"specularPlacement", @"sourceObjectVersion"
    ];

    for (NSString *prop in properties) {
        id val = getValueViaSelector(layer, prop);
        if (val) dict[prop] = val;
    }

    // frame 结构体读取
    if ([layer respondsToSelector:@selector(frame)]) {
        CGRect f = ((CGRect (*)(id, SEL))objc_msgSend)(layer, @selector(frame));
        dict[@"frame"] = [NSString stringWithFormat:@"{{%g, %g}, {%g, %g}}", f.origin.x, f.origin.y, f.size.width, f.size.height];
    }

    // 单色填充
    if ([layer respondsToSelector:NSSelectorFromString(@"color")]) {
        CGColorRef c = ((CGColorRef (*)(id, SEL))objc_msgSend)(layer, NSSelectorFromString(@"color"));
        if (c) dict[@"color"] = colorToJSON(c);
    }

    // 渐变填充
    id grad = getValueViaSelector(layer, @"gradient");
    if (grad) {
        NSMutableArray *colorsArr = [NSMutableArray array];
        NSArray *colors = getValueViaSelector(grad, @"colors");
        if ([colors isKindOfClass:[NSArray class]]) {
            for (id c in colors) {
                [colorsArr addObject:colorToJSON((__bridge CGColorRef)c)];
            }
        }
        CGPoint sp = CGPointZero;
        CGPoint ep = CGPointZero;
        if ([grad respondsToSelector:NSSelectorFromString(@"gradientStartPoint")]) {
            sp = ((CGPoint (*)(id, SEL))objc_msgSend)(grad, NSSelectorFromString(@"gradientStartPoint"));
        }
        if ([grad respondsToSelector:NSSelectorFromString(@"gradientEndPoint")]) {
            ep = ((CGPoint (*)(id, SEL))objc_msgSend)(grad, NSSelectorFromString(@"gradientEndPoint"));
        }
        dict[@"gradient"] = @{
            @"name": getValueViaSelector(grad, @"name") ?: @"?",
            @"type": getValueViaSelector(grad, @"gradientType") ?: @(-1),
            @"start": [NSString stringWithFormat:@"{%g, %g}", sp.x, sp.y],
            @"end": [NSString stringWithFormat:@"{%g, %g}", ep.x, ep.y],
            @"stops": getValueViaSelector(grad, @"colorStops") ?: @[],
            @"colors": colorsArr
        };
    }

    NSString *lname = getValueViaSelector(layer, @"name") ?: @"unnamed";

    // 提取位图 (PNG)
    if ([layer respondsToSelector:NSSelectorFromString(@"image")] && ![layer isKindOfClass:NSClassFromString(@"CUINamedVectorSVGImage")]) {
        CGImageRef img = ((CGImageRef (*)(id, SEL))objc_msgSend)(layer, NSSelectorFromString(@"image"));
        if (img) {
            NSString *fileName = [NSString stringWithFormat:@"%@__%@.png", safeFileName(lname), appearance];
            NSString *savePath = [outDir stringByAppendingPathComponent:fileName];
            [QxCarCoreUIBridge saveCGImage:img toPath:savePath];
            dict[@"savedImage"] = fileName;
            dict[@"imageSize"] = [NSString stringWithFormat:@"%zux%zu", CGImageGetWidth(img), CGImageGetHeight(img)];
        }
    }

    // 提取矢量 (SVG)
    if ([layer isKindOfClass:NSClassFromString(@"CUINamedVectorSVGImage")]) {
        CGSVGDocumentRef doc = ((CGSVGDocumentRef (*)(id, SEL))objc_msgSend)(layer, NSSelectorFromString(@"svgDocument"));
        if (doc && CGSVGDocumentWriteToURL_) {
            NSString *fileName = [NSString stringWithFormat:@"%@__%@.svg", safeFileName(lname), appearance];
            NSString *savePath = [outDir stringByAppendingPathComponent:fileName];
            CGSVGDocumentWriteToURL_(doc, (__bridge CFURLRef)[NSURL fileURLWithPath:savePath], NULL);
            dict[@"savedSVG"] = fileName;
        }
    }

    // 递归子图层 (CUINamedIconLayerGroup)
    NSArray *subLayers = getValueViaSelector(layer, @"layers");
    if ([subLayers isKindOfClass:[NSArray class]]) {
        NSMutableArray *subDumps = [NSMutableArray array];
        for (id sl in subLayers) {
            [subDumps addObject:dumpLayerNode(sl, outDir, appearance)];
        }
        dict[@"layers"] = subDumps;
    }

    return dict;
}

static NSDictionary *resolveGradientLookup(id lk, id catalog, NSString *appearance) {
    if (!lk) return @{};
    SEL updateSel = NSSelectorFromString(@"_updateFromCatalog:displayGamut:deviceIdiom:appearanceName:");
    if ([lk respondsToSelector:updateSel]) {
        ((void (*)(id, SEL, id, long long, long long, id))objc_msgSend)(lk, updateSel, catalog, 0LL, 0LL, appearance);
    }
    NSMutableDictionary *res = [NSMutableDictionary dictionary];
    NSArray *colors = getValueViaSelector(lk, @"colors");
    if ([colors isKindOfClass:[NSArray class]]) {
        NSMutableArray *cj = [NSMutableArray array];
        for (id c in colors) {
            [cj addObject:colorToJSON((__bridge CGColorRef)c)];
        }
        res[@"colors"] = cj;
    }
    id stops = getValueViaSelector(lk, @"colorStops");
    if (stops) res[@"stops"] = stops;
    id type = getValueViaSelector(lk, @"gradientType");
    if (type) res[@"type"] = type;

    if ([lk respondsToSelector:NSSelectorFromString(@"gradientStartPoint")]) {
        CGPoint sp = ((CGPoint (*)(id, SEL))objc_msgSend)(lk, NSSelectorFromString(@"gradientStartPoint"));
        CGPoint ep = ((CGPoint (*)(id, SEL))objc_msgSend)(lk, NSSelectorFromString(@"gradientEndPoint"));
        res[@"start"] = @[@(sp.x), @(sp.y)];
        res[@"end"] = @[@(ep.x), @(ep.y)];
    }
    return res;
}

+ (nullable NSDictionary<NSString *, id> *)dumpIconStackFromCatalog:(id)catalog
                                                           iconName:(NSString *)iconName
                                                          outputDir:(NSString *)outDir {
    if (!catalog || !iconName) return nil;
    [self ensureFrameworksLoaded];

    [[NSFileManager defaultManager] createDirectoryAtPath:outDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    NSMutableDictionary *result = [NSMutableDictionary dictionary];

    NSArray *appearances = @[
        @"NSAppearanceNameAqua", @"NSAppearanceNameDarkAqua",
        @"ISAppearanceTintable", @"UIAppearanceAny", @"UIAppearanceDark",
        [NSNull null], @"UIAppearanceLight"
    ];

    SEL stackSel = NSSelectorFromString(@"iconLayerStackWithName:scaleFactor:deviceIdiom:deviceSubtype:displayGamut:appearanceName:locale:");
    if (![catalog respondsToSelector:stackSel]) {
        return nil;
    }

    for (id appObj in appearances) {
        NSString *app = [appObj isKindOfClass:[NSNull class]] ? nil : appObj;
        NSString *key = app ?: @"Default";
        if (result[key]) continue;

        id stack = ((id (*)(id, SEL, id, double, long long, unsigned long long, long long, id, id))objc_msgSend)(
            catalog, stackSel, iconName, 1.0, 0, 0, 0, app, nil
        );

        if (!stack) {
            result[key] = @"NOT FOUND";
            continue;
        }

        NSMutableDictionary *stackDict = [NSMutableDictionary dictionary];
        stackDict[@"class"] = NSStringFromClass([stack class]);

        id rp = getValueViaSelector(stack, @"renderingProperties");
        if (rp) stackDict[@"renderingProperties"] = [rp description];

        NSArray *groups = getValueViaSelector(stack, @"layers");
        if ([groups isKindOfClass:[NSArray class]]) {
            // 解析前置画布背景 (CUINamedGradient / CUINamedColor)
            for (id g in groups) {
                NSString *gcls = NSStringFromClass([g class]);
                if ([gcls containsString:@"LayerGroup"]) break;
                if ([gcls containsString:@"Gradient"]) {
                    stackDict[@"canvasFill"] = resolveGradientLookup(g, catalog, app);
                    break;
                }
                if ([gcls containsString:@"Color"]) {
                    if ([g respondsToSelector:NSSelectorFromString(@"cgColor")]) {
                        CGColorRef cc = ((CGColorRef (*)(id, SEL))objc_msgSend)(g, NSSelectorFromString(@"cgColor"));
                        if (cc) stackDict[@"canvasFill"] = @{ @"colors": @[colorToJSON(cc)] };
                    }
                    break;
                }
            }

            NSMutableArray *groupDumps = [NSMutableArray array];
            for (id g in groups) {
                [groupDumps addObject:dumpLayerNode(g, outDir, key)];
            }
            stackDict[@"groups"] = groupDumps;
        }

        result[key] = stackDict;
    }

    // 捕获 system-light/system-dark 命名渐变
    @try {
        if ([catalog respondsToSelector:NSSelectorFromString(@"enumerateNamedLookupsUsingBlock:")]) {
            NSMutableArray *bgLookups = [NSMutableArray array];
            void (^block)(id) = ^(id lk) {
                NSString *nm = getValueViaSelector(lk, @"name");
                if (nm && [nm containsString:@"system-"]) [bgLookups addObject:lk];
            };
            ((void (*)(id, SEL, id))objc_msgSend)(catalog, NSSelectorFromString(@"enumerateNamedLookupsUsingBlock:"), block);

            NSMutableDictionary *bg = [NSMutableDictionary dictionary];
            for (id lk in bgLookups) {
                NSString *nm = getValueViaSelector(lk, @"name");
                NSString *leaf = [nm componentsSeparatedByString:@"/"].lastObject;
                NSMutableDictionary *byApp = [NSMutableDictionary dictionary];
                for (NSString *app in @[@"UIAppearanceLight", @"UIAppearanceDark"]) {
                    NSDictionary *g = resolveGradientLookup(lk, catalog, app);
                    if (g.count) byApp[app] = g;
                }
                if (byApp.count) bg[leaf] = byApp;
            }
            if (bg.count) result[@"_background"] = bg;
        }
    } @catch (NSException *ex) {}

    return result;
}

+ (BOOL)exportAssetFromCatalog:(id)catalog
                          name:(NSString *)name
                         scale:(double)scale
                    outputPath:(NSString *)outPath {
    if (!catalog || !name || !outPath) return NO;
    [self ensureFrameworksLoaded];

    SEL lookupSel = NSSelectorFromString(@"_namedLookupWithName:scaleFactor:deviceIdiom:deviceSubtype:displayGamut:layoutDirection:sizeClassHorizontal:sizeClassVertical:appearanceName:locale:");
    if (![catalog respondsToSelector:lookupSel]) return NO;

    id lookup = ((id (*)(id, SEL, id, double, long long, unsigned long long, long long, long long, long long, long long, id, id))objc_msgSend)(
        catalog, lookupSel, name, scale, 0, 0, 0, 0, 0, 0, nil, nil
    );
    if (!lookup) return NO;

    // 如果是 SVG
    if ([lookup isKindOfClass:NSClassFromString(@"CUINamedVectorSVGImage")]) {
        CGSVGDocumentRef doc = ((CGSVGDocumentRef (*)(id, SEL))objc_msgSend)(lookup, NSSelectorFromString(@"svgDocument"));
        if (doc && CGSVGDocumentWriteToURL_) {
            CGSVGDocumentWriteToURL_(doc, (__bridge CFURLRef)[NSURL fileURLWithPath:outPath], NULL);
            return YES;
        }
    }

    // 如果是 PDF (CUINamedVectorPDFImage)
    if ([lookup respondsToSelector:NSSelectorFromString(@"pdfDocument")]) {
        CGPDFDocumentRef pdf = ((CGPDFDocumentRef (*)(id, SEL))objc_msgSend)(lookup, NSSelectorFromString(@"pdfDocument"));
        if (pdf) {
            // PDF 数据导出
            SEL rawDataSel = NSSelectorFromString(@"_rawData");
            if ([lookup respondsToSelector:rawDataSel]) {
                NSData *data = ((NSData *(*)(id, SEL))objc_msgSend)(lookup, rawDataSel);
                if (data) {
                    return [data writeToFile:outPath atomically:YES];
                }
            }
        }
    }

    // 如果是位图 (CUINamedImage)
    if ([lookup respondsToSelector:NSSelectorFromString(@"image")]) {
        CGImageRef img = ((CGImageRef (*)(id, SEL))objc_msgSend)(lookup, NSSelectorFromString(@"image"));
        if (img) {
            return [self saveCGImage:img toPath:outPath];
        }
    }

    return NO;
}

@end
