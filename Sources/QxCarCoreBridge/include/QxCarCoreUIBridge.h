#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

/**
 * QxCarCoreUIBridge
 * 底层 CoreUI 与 CoreSVG 私有框架动态桥接接口，用于读取 Assets.car、导出图像/SVG 及逆向解析 .icon 图层栈。
 */
@interface QxCarCoreUIBridge : NSObject

/**
 * 确保动态加载 CoreUI 与 CoreSVG 框架
 * @return 是否成功加载
 */
+ (BOOL)ensureFrameworksLoaded;

/**
 * 打开 Assets.car 目录并返回 CUICatalog 实例
 * @param carPath Assets.car 文件的绝对路径
 * @param error 错误信息输出
 * @return CUICatalog 对象（如果失败返回 nil）
 */
+ (nullable id)openCatalogWithPath:(NSString *)carPath error:(NSError **)error;

/**
 * 获取 Catalog 中所有的图标堆栈 (IconImageStack) 名称列表
 * @param catalog CUICatalog 实例
 * @return 图标堆栈名称数组 (例如 ["AppIcon", "AppIconUpdated"])
 */
+ (NSArray<NSString *> *)getIconStackNamesFromCatalog:(id)catalog;

/**
 * 获取 Catalog 中所有图片素材名称
 * @param catalog CUICatalog 实例
 * @return 图片素材名称数组
 */
+ (NSArray<NSString *> *)getAllImageNamesFromCatalog:(id)catalog;

/**
 * 导出图层栈（递归解析各个图层属性、材质特效与图层矢量 SVG/PNG 文件）
 * @param catalog CUICatalog 实例
 * @param iconName 图标栈名称
 * @param outDir 临时/输出资产保存目录
 * @return 包含各外观（Default, Dark, Tinted 等）的图层栈结构字典
 */
+ (nullable NSDictionary<NSString *, id> *)dumpIconStackFromCatalog:(id)catalog
                                                           iconName:(NSString *)iconName
                                                          outputDir:(NSString *)outDir;

/**
 * 导出指定名称的普通矢量/位图资源至目标路径
 * @param catalog CUICatalog 实例
 * @param name 资源名称
 * @param scale 比例因子 (1.0, 2.0, 3.0)
 * @param outPath 保存的目标文件绝对路径
 * @return 是否导出成功
 */
+ (BOOL)exportAssetFromCatalog:(id)catalog
                          name:(NSString *)name
                         scale:(double)scale
                    outputPath:(NSString *)outPath;

/**
 * 将 CGImageRef 保存为 PNG 文件
 * @param image CGImageRef
 * @param path 目标路径
 * @return 是否保存成功
 */
+ (BOOL)saveCGImage:(CGImageRef)image toPath:(NSString *)path;

@end

NS_ASSUME_NONNULL_END
