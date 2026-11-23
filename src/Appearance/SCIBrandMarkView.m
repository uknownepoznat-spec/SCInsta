#import "SCIBrandMarkView.h"

@implementation SCIBrandMarkView
- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColor.clearColor;
        self.contentMode = UIViewContentModeRedraw;
        self.tintColor = [UIColor colorWithRed:0.659 green:0.612 blue:1 alpha:1];
        self.isAccessibilityElement = YES;
        self.accessibilityLabel = @"Peki Scripter V2";
    }
    return self;
}
- (void)tintColorDidChange {
    [super tintColorDidChange];
    [self setNeedsDisplay];
}
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) return;
    CGContextSaveGState(context);
    CGFloat scale = MIN(self.bounds.size.width, self.bounds.size.height) / 56.0;
    CGContextTranslateCTM(context, (self.bounds.size.width - 56 * scale) / 2,
        (self.bounds.size.height - 56 * scale) / 2);
    CGContextScaleCTM(context, scale, scale);
    [self.tintColor setStroke];
    [self.tintColor setFill];
    UIBezierPath *frame = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(4, 4, 48, 48) cornerRadius:14];
    frame.lineWidth = 2.8;
    [frame stroke];
    UIBezierPath *lens = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(17, 17, 22, 22)];
    lens.lineWidth = 2.8;
    [lens stroke];
    [[UIBezierPath bezierPathWithOvalInRect:CGRectMake(38, 11, 6, 6)] fill];
    CGContextRestoreGState(context);
}
@end
