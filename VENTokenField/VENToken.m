// VENToken.m
//
// Copyright (c) 2014 Venmo
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "VENToken.h"

@interface VENToken ()

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *deleteButton;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *titleLabel;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *leftViewContainer;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *backgroundButton;

@end

@implementation VENToken

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    self = [[[NSBundle bundleForClass:[self class]] loadNibNamed:NSStringFromClass([self class]) owner:self options:nil] firstObject];
    if (self) {
        [self setUpInit];
    }
    return self;
}

- (void)setUpInit
{
    UIImage *deleteImage = [self.deleteButton imageForState:UIControlStateNormal];
    deleteImage = [deleteImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.deleteButton setImage:deleteImage forState:UIControlStateNormal];
}

- (void)setLeftView:(UIView *)view
{
    view.frame = self.leftViewContainer.bounds;
    for (UIView *subview in self.leftViewContainer.subviews) {
        [subview removeFromSuperview];
    }
    
    [self.leftViewContainer addSubview:view];
}

- (void)setTitle:(NSString *)title
{
    self.titleLabel.text = title;
    self.titleLabel.textColor = self.colorScheme.textColor;
    [self.titleLabel sizeToFit];
    
    CGFloat expectedWidth = CGRectGetWidth(self.titleLabel.frame);
    
    if (expectedWidth > 106) {
        expectedWidth = 106;
    }
    
    CGRect titleLabelFrame = self.titleLabel.frame;
    titleLabelFrame.origin.y = 0;
    titleLabelFrame.size.height = CGRectGetHeight(self.frame);
    titleLabelFrame.size.width = expectedWidth;

    self.frame = CGRectMake(CGRectGetMaxX(self.frame) + 3, CGRectGetMinY(self.frame), CGRectGetWidth(titleLabelFrame) + 74, CGRectGetHeight(self.frame));
    
    self.titleLabel.frame = titleLabelFrame;
}

- (void)setHighlighted:(BOOL)highlighted
{
    _highlighted = highlighted;
    [self updateColors];
}

- (void)setColorScheme:(VENTokenColorScheme *)colorScheme
{
    _colorScheme = colorScheme;
    [self updateColors];
}

- (void)updateColors
{
    VENTokenColorScheme *colors = self.colorScheme;
    
    if (!colors) {
        return;
    }
    
    UIColor *textAndXColor =  _highlighted ? colors.highlightedTextColor : colors.textColor;

    self.titleLabel.textColor = textAndXColor;
    self.deleteButton.tintColor = textAndXColor;
    
    self.deleteButton.backgroundColor = _highlighted ? colors.highlightedDeleteButtonBackgroundColorColor : colors.deleteButtonBackgroundColor;
    self.backgroundButton.backgroundColor = _highlighted ? colors.highlightedBackgroundColor : colors.backgroundColor;
}

#pragma mark - Private

- (IBAction)didTapTokenButton:(id)sender
{
    if (self.didTapTokenBlock) {
        self.didTapTokenBlock();
    }
}

- (IBAction)didTapDeleteButton:(id)sender
{
    if (self.didTapDeleteBlock) {
        self.didTapDeleteBlock();
    }
}

@end
