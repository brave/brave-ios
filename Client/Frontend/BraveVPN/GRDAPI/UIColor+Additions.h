
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, SQFContrastingColorMethod) {
    SQFContrastingColorFiftyPercentMethod,
    SQFContrastingColorYIQMethod
};

@interface UIColor (Additions)

#define UIColorFromRGB(rgbValue, alp) [UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 green:((float)((rgbValue & 0xFF00) >> 8))/255.0 blue:((float)(rgbValue & 0xFF))/255.0 alpha:alp]

+ (UIColor *)pageHijackerPurpleSelected:(BOOL)selected;
+ (UIColor *)dataTrackerYellowSelected:(BOOL)selected;
+ (UIColor *)locationTrackerGreenSelected:(BOOL)selected;
+ (UIColor *)mailTrackerRedSelected:(BOOL)selected;
+ (UIColor *)colorFromHex:(NSString *)s alpha:(CGFloat)alpha;
- (UIColor *)changeBrightnessByAmount:(CGFloat)amount;
+ (UIColor *)changeBrightness:(UIColor*)color amount:(CGFloat)amount;
- (NSString *)hexValue;

+ (UIColor *)colorFromHex:(NSString *)s;
- (UIColor *)sqf_contrastingColorWithMethod:(SQFContrastingColorMethod)method;
@end
