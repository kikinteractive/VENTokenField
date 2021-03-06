// VENTokenField.m
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

#import "VENTokenField.h"
#import "VENTokenColorScheme.h"
#import <FrameAccessor/FrameAccessor.h>
#import "VENToken.h"
#import "VENBackspaceTextField.h"

static const CGFloat VENTokenFieldDefaultVerticalInset        = 5.0;
static const CGFloat VENTokenFieldDefaultDismissButtonSpacing = 50.0;
static const CGFloat VENTokenFieldDefaultToLabelPadding       = 5.0;
static const CGFloat VENTokenFieldDefaultTokenPadding         = 2.0;
static const CGFloat VENTokenFieldDefaultMinInputWidth        = 80.0;
static const CGFloat VENTokenFieldDefaultMaxHeight            = 150.0;

@interface VENTokenField () <VENBackspaceTextFieldDelegate>

@property (strong, nonatomic) UIScrollView *scrollView;
@property (strong, nonatomic) NSMutableArray *tokens;
@property (assign, nonatomic) CGFloat originalHeight;
@property (strong, nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (strong, nonatomic) VENBackspaceTextField *invisibleTextField;
@property (strong, nonatomic) VENBackspaceTextField *inputTextField;
@property (strong, nonatomic) VENTokenColorScheme *colorScheme;
@property (strong, nonatomic) UILabel *collapsedLabel;
@property (strong, nonatomic) UIButton *dismissButton;
@property (assign, nonatomic) CGFloat dismissButtonSpacing;

@end

@implementation VENTokenField

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setUpInit];
    }
    return self;
}

- (void)awakeFromNib
{
    [self setUpInit];
}

- (BOOL)isFirstResponder
{
    return [self.inputTextField isFirstResponder];
}

- (BOOL)becomeFirstResponder
{
    [self layoutTokensAndInputWithFrameAdjustment:YES];
    [self inputTextFieldBecomeFirstResponder];
    return YES;
}

- (BOOL)resignFirstResponder
{
    [super resignFirstResponder];
    return [self.inputTextField resignFirstResponder];
}

- (void)setUpInit
{
    // Set up default values.
    _autocorrectionType = UITextAutocorrectionTypeNo;
    _autocapitalizationType = UITextAutocapitalizationTypeSentences;
    self.maxHeight = VENTokenFieldDefaultMaxHeight;
    self.tokenPadding = VENTokenFieldDefaultTokenPadding;
    self.minInputWidth = VENTokenFieldDefaultMinInputWidth;
    self.colorScheme = [[VENTokenColorScheme alloc] init];
    self.toLabelTextColor = [UIColor colorWithRed:112/255.0f green:124/255.0f blue:124/255.0f alpha:1.0f];
    self.inputTextFieldTextColor = [UIColor colorWithRed:38/255.0f green:39/255.0f blue:41/255.0f alpha:1.0f];
    
    // Accessing bare value to avoid kicking off a premature layout run.
    _toLabelText = NSLocalizedString(@"To:", nil);

    self.originalHeight = CGRectGetHeight(self.frame);

    // Add invisible text field to handle backspace when we don't have a real first responder.
    [self layoutInvisibleTextField];

    [self layoutScrollView];
    [self reloadData];
}

- (void)collapse
{
    [self layoutCollapsedLabel];
}

- (void)reloadDataAndFlashScrollIndicators
{
    [self reloadData];
    [self.scrollView flashScrollIndicators];
}

- (void)reloadData
{
    [self layoutTokensAndInputWithFrameAdjustment:YES];
    [self updateInputPlaceholder];
}

- (void)setAttributedPlaceholder:(NSAttributedString *)attributedPlaceholder
{
    _attributedPlaceholder = attributedPlaceholder;
    
    self.inputTextField.attributedPlaceholder = attributedPlaceholder;
}

-(void)setInputTextFieldAccessibilityLabel:(NSString *)inputTextFieldAccessibilityLabel
{
    _inputTextFieldAccessibilityLabel = inputTextFieldAccessibilityLabel;
    
    self.inputTextField.accessibilityLabel = _inputTextFieldAccessibilityLabel;
}

- (void)setInputTextFieldTextColor:(UIColor *)inputTextFieldTextColor
{
    _inputTextFieldTextColor = inputTextFieldTextColor;
    
    self.inputTextField.textColor = _inputTextFieldTextColor;
    self.inputTextField.tintColor = _inputTextFieldTextColor;
}

- (void)setToLabelTextColor:(UIColor *)toLabelTextColor
{
    _toLabelTextColor = toLabelTextColor;
    
    self.toLabel.textColor = _toLabelTextColor;
}

- (void)setToLabelText:(NSString *)toLabelText
{
    _toLabelText = toLabelText;
    [self reloadData];
}

- (void)setColorScheme:(VENTokenColorScheme *)colorScheme
{
    if (!colorScheme) {
        return;
    }
    
    _colorScheme = colorScheme;
    self.collapsedLabel.textColor = colorScheme.textColor;
    self.inputTextField.tintColor = colorScheme.textColor;
    for (VENToken *token in self.tokens) {
        [token setColorScheme:colorScheme];
    }
}

- (void)setInputTextFieldAccessoryView:(UIView *)inputTextFieldAccessoryView
{
    _inputTextFieldAccessoryView = inputTextFieldAccessoryView;
    self.inputTextField.inputAccessoryView = _inputTextFieldAccessoryView;
}

- (NSString *)inputText
{
    return self.inputTextField.text;
}

#pragma mark - View Layout

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame) - 8.0, CGRectGetHeight(self.frame) - VENTokenFieldDefaultVerticalInset * 2);
    self.scrollView.contentInset = UIEdgeInsetsMake(VENTokenFieldDefaultVerticalInset, 0, VENTokenFieldDefaultVerticalInset, 8.0);
    
    if ([self isCollapsed]) {
        [self layoutCollapsedLabel];
    } else {
        [self layoutTokensAndInputWithFrameAdjustment:NO];
    }
}

- (void)layoutCollapsedLabel
{
    [self.collapsedLabel removeFromSuperview];
    self.scrollView.hidden = YES;
    [self setHeight:self.originalHeight];

    CGFloat currentX = 0;
    [self layoutToLabelInView:self origin:CGPointMake(0, VENTokenFieldDefaultVerticalInset) currentX:&currentX];
    [self layoutCollapsedLabelWithCurrentX:&currentX];

    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                        action:@selector(handleSingleTap:)];
    [self addGestureRecognizer:self.tapGestureRecognizer];
}

- (void)layoutTokensAndInputWithFrameAdjustment:(BOOL)shouldAdjustFrame
{
    [self.collapsedLabel removeFromSuperview];
    BOOL inputFieldShouldBecomeFirstResponder = self.inputTextField.isFirstResponder;

    for (UIView *subview in self.scrollView.subviews) {
        if ([subview isKindOfClass:[UIImageView class]] == NO) {
            [subview removeFromSuperview];
        }
    }
    
    self.scrollView.hidden = NO;
    [self removeGestureRecognizer:self.tapGestureRecognizer];

    self.tokens = [NSMutableArray array];

    CGFloat currentX = 0;
    CGFloat currentY = 0;

    [self layoutToLabelInView:self.scrollView origin:CGPointZero currentX:&currentX];
    [self layoutTokensWithCurrentX:&currentX currentY:&currentY];
    [self layoutInputTextFieldWithCurrentX:&currentX currentY:&currentY clearInput:shouldAdjustFrame];

    if (shouldAdjustFrame) {
        [self adjustHeightForCurrentY:currentY];
    }

    self.scrollView.contentSize = CGSizeMake(self.scrollView.contentSize.width, currentY + [self heightForToken]);
    
    [self updateInputPlaceholder];

    if (inputFieldShouldBecomeFirstResponder) {
        [self inputTextFieldBecomeFirstResponder];
    } else {
        [self focusInputTextField];
    }
}

- (BOOL)isCollapsed
{
    return self.collapsedLabel.superview != nil;
}

- (void)layoutScrollView
{
    self.scrollView = [[UIScrollView alloc] init];
    [self setupScrollViewFrame];
    self.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    self.scrollView.scrollsToTop = NO;
    self.scrollView.contentSize = CGSizeMake(CGRectGetWidth(self.scrollView.frame) - 8.0, CGRectGetHeight(self.frame) - VENTokenFieldDefaultVerticalInset * 2);

    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;

    [self.scrollView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                                  action:@selector(handleSingleTapOnScrollView:)]];

    [self addSubview:self.scrollView];
}

- (void)layoutInputTextFieldWithCurrentX:(CGFloat *)currentX currentY:(CGFloat *)currentY clearInput:(BOOL)clearInput
{
    CGFloat inputTextFieldWidth = self.scrollView.contentSize.width - *currentX;
    if (inputTextFieldWidth < self.minInputWidth) {
        inputTextFieldWidth = self.scrollView.contentSize.width;
        *currentY += [self heightForToken];
        *currentX = 0;
    }

    VENBackspaceTextField *inputTextField = self.inputTextField;
    if (clearInput) {
        inputTextField.text = @"";
    }
    inputTextField.frame = CGRectMake(*currentX, *currentY + 1, inputTextFieldWidth, [self heightForToken] - 1);
    inputTextField.tintColor = self.colorScheme.textColor;
    [self.scrollView addSubview:inputTextField];
}

- (void)layoutCollapsedLabelWithCurrentX:(CGFloat *)currentX
{
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(*currentX, CGRectGetMinY(self.toLabel.frame), self.width - *currentX, self.toLabel.height)];
    label.font = [UIFont fontWithName:@"ProximaNova-Regular" size:16];
    label.text = [self collapsedText];
    label.textColor = self.colorScheme.textColor;
    label.minimumScaleFactor = 5./label.font.pointSize;
    label.adjustsFontSizeToFitWidth = YES;
    [self addSubview:label];
    self.collapsedLabel = label;
}

- (void)layoutToLabelInView:(UIView *)view origin:(CGPoint)origin currentX:(CGFloat *)currentX
{
    [self.dismissButton removeFromSuperview];
    
    if (self.showDismissButton) {
        if ([self.delegate respondsToSelector:@selector(tokenFieldDidTapDismiss:)] == NO) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"when `showDismissButton` is set to YES, the VENTokenFieldDelegate must respond to tokenFieldDidTapDismiss" userInfo:nil];
        }
        if (!self.dismissButtonImage) {
            @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"when `showDismissButton` is set to YES, the dismissButtonImage property must be set" userInfo:nil];
        }
        
        self.dismissButton = [UIButton buttonWithType:UIButtonTypeCustom];
        if (self.dismissButtonTintColor) {
            self.dismissButton.tintColor = self.dismissButtonTintColor;
        }
        else {
            self.dismissButton.tintColor = [UIColor whiteColor];
        }
        
        [self.dismissButton addTarget:self action:@selector(didTapDismiss:) forControlEvents:UIControlEventTouchDown];
        [self.dismissButton setImage:[self.dismissButtonImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.dismissButton sizeToFit];
        [self addSubview:self.dismissButton];

        CGRect buttonFrame = self.dismissButton.frame;
        buttonFrame.origin = CGPointMake(15, 10);
        self.dismissButton.frame = buttonFrame;
    }
    
    [self.toLabel removeFromSuperview];
    self.toLabel = [self toLabel];
    
    CGRect newFrame = self.toLabel.frame;
    newFrame.origin = origin;
    
    [self.toLabel sizeToFit];
    newFrame.size.width = CGRectGetWidth(self.toLabel.frame);
    
    self.toLabel.frame = newFrame;
    
    [view addSubview:self.toLabel];
    
    BOOL isHidden = self.toLabel.hidden || self.toLabel.text.length == 0;
    
    *currentX += isHidden ? CGRectGetMinX(self.toLabel.frame) : CGRectGetMaxX(self.toLabel.frame) + VENTokenFieldDefaultToLabelPadding;
}

- (void)layoutTokensWithCurrentX:(CGFloat *)currentX currentY:(CGFloat *)currentY
{
    for (NSUInteger i = 0; i < [self numberOfTokens]; i++) {
        VENToken *token = [[VENToken alloc] init];

        __weak VENToken *weakToken = token;
        __weak VENTokenField *weakSelf = self;
        token.didTapTokenBlock = ^{
            [weakSelf didTapToken:weakToken];
        };
        token.didTapDeleteBlock = ^{
            [weakSelf didTapDeleteToken:weakToken];
        };
        
        [token setTitle:[self titleForTokenAtIndex:i]];
        [token setLeftView:[self leftViewForTokenAtIndex:i]];
        token.colorScheme = [self colorSchemeForTokenAtIndex:i];
        
        [self.tokens addObject:token];
        
        if (*currentX + token.width <= self.scrollView.contentSize.width) { // token fits in current line
            token.frame = CGRectMake(*currentX, *currentY, token.width, token.height);
        } else {
            *currentY += token.height + 3;
            *currentX = 0;
            CGFloat tokenWidth = token.width;
            if (tokenWidth > self.scrollView.contentSize.width) { // token is wider than max width
                tokenWidth = self.scrollView.contentSize.width;
            }
            token.frame = CGRectMake(*currentX, *currentY, tokenWidth, token.height);
        }
        *currentX += token.width + self.tokenPadding;
        [self.scrollView addSubview:token];
    }
}

- (void)setupScrollViewFrame
{
    self.scrollView.frame = CGRectMake(self.dismissButtonSpacing, 0, CGRectGetWidth(self.frame) - self.dismissButtonSpacing, CGRectGetHeight(self.frame));
}

#pragma mark - Private

- (CGFloat)heightForToken
{
    return 35;
}

- (void)layoutInvisibleTextField
{
    self.invisibleTextField = [[VENBackspaceTextField alloc] initWithFrame:CGRectZero];
    [self.invisibleTextField setAutocorrectionType:self.autocorrectionType];
    [self.invisibleTextField setAutocapitalizationType:self.autocapitalizationType];
    self.invisibleTextField.backspaceDelegate = self;
    [self addSubview:self.invisibleTextField];
}

- (void)inputTextFieldBecomeFirstResponder
{
    if (self.inputTextField.isFirstResponder) {
        return;
    }

    [self.inputTextField becomeFirstResponder];
    if ([self.delegate respondsToSelector:@selector(tokenFieldDidBeginEditing:)]) {
        [self.delegate tokenFieldDidBeginEditing:self];
    }
}

- (UILabel *)toLabel
{
    if (!_toLabel) {
        _toLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _toLabel.textColor = self.toLabelTextColor;
        _toLabel.font = [UIFont fontWithName:@"ProximaNova-Regular" size:16];
        _toLabel.x = 0;
        [_toLabel sizeToFit];
        [_toLabel setHeight:[self heightForToken]];
    }
    if (![_toLabel.text isEqualToString:_toLabelText]) {
        _toLabel.text = _toLabelText;
    }
    return _toLabel;
}

- (void)adjustHeightForCurrentY:(CGFloat)currentY
{
    CGFloat oldHeight = self.height;
    CGFloat height;
    if (currentY + [self heightForToken] > CGRectGetHeight(self.frame)) { // needs to grow
        if (currentY + [self heightForToken] <= self.maxHeight) {
            height = currentY + [self heightForToken] + VENTokenFieldDefaultVerticalInset * 2;
        } else {
            height = self.maxHeight;
        }
    } else { // needs to shrink
        if (currentY + [self heightForToken] > self.originalHeight) {
            height = currentY + [self heightForToken] + VENTokenFieldDefaultVerticalInset * 2;
        } else {
            height = self.originalHeight;
        }
    }
    if (oldHeight != height) {
        [self setHeight:height];
        if ([self.delegate respondsToSelector:@selector(tokenField:didChangeContentHeight:)]) {
            [self.delegate tokenField:self didChangeContentHeight:height];
        }
    }
}

- (VENBackspaceTextField *)inputTextField
{
    if (!_inputTextField) {
        _inputTextField = [[VENBackspaceTextField alloc] init];
        [_inputTextField setKeyboardType:self.inputTextFieldKeyboardType];
        _inputTextField.textColor = self.inputTextFieldTextColor;
        _inputTextField.font = [UIFont fontWithName:@"ProximaNova-Regular" size:16];
        _inputTextField.autocorrectionType = self.autocorrectionType;
        _inputTextField.autocapitalizationType = self.autocapitalizationType;
        _inputTextField.tintColor = self.colorScheme.textColor;
        _inputTextField.delegate = self;
        _inputTextField.backspaceDelegate = self;
        _inputTextField.attributedPlaceholder = self.attributedPlaceholder;
        _inputTextField.accessibilityLabel = self.inputTextFieldAccessibilityLabel ?: NSLocalizedString(@"To", nil);
        _inputTextField.inputAccessoryView = self.inputTextFieldAccessoryView;
        [_inputTextField addTarget:self action:@selector(inputTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    }
    return _inputTextField;
}

- (void)setAutocorrectionType:(UITextAutocorrectionType)autocorrectionType
{
    _autocorrectionType = autocorrectionType;
    [self.inputTextField setAutocorrectionType:self.autocorrectionType];
    [self.invisibleTextField setAutocorrectionType:self.autocorrectionType];
}

- (void)setInputTextFieldKeyboardAppearance:(UIKeyboardAppearance)inputTextFieldKeyboardAppearance
{
    _inputTextFieldKeyboardAppearance = inputTextFieldKeyboardAppearance;
    [self.inputTextField setKeyboardAppearance:self.inputTextFieldKeyboardAppearance];
}

- (void)setInputTextFieldKeyboardType:(UIKeyboardType)inputTextFieldKeyboardType
{
    _inputTextFieldKeyboardType = inputTextFieldKeyboardType;
    [self.inputTextField setKeyboardType:self.inputTextFieldKeyboardType];
}

- (void)setAutocapitalizationType:(UITextAutocapitalizationType)autocapitalizationType
{
    _autocapitalizationType = autocapitalizationType;
    [self.inputTextField setAutocapitalizationType:self.autocapitalizationType];
    [self.invisibleTextField setAutocapitalizationType:self.autocapitalizationType];
}

- (void)setShowDismissButton:(BOOL)showDismissButton
{
    _showDismissButton = showDismissButton;
    
    self.dismissButtonSpacing = showDismissButton ? VENTokenFieldDefaultDismissButtonSpacing : 0;
    
    [self setupScrollViewFrame];
}

- (void)inputTextFieldDidChange:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(tokenField:didChangeText:)]) {
        [self.delegate tokenField:self didChangeText:textField.text];
    }
}

- (void)handleSingleTap:(UITapGestureRecognizer *)gestureRecognizer
{
    [self becomeFirstResponder];
}

- (void)handleSingleTapOnScrollView:(UITapGestureRecognizer *)gestureRecognizer
{
    [self inputTextFieldBecomeFirstResponder];
}

- (void)didTapToken:(VENToken *)token
{
    for (VENToken *aToken in self.tokens) {
        if (aToken == token) {
            aToken.highlighted = !aToken.highlighted;
        } else {
            aToken.highlighted = NO;
        }
    }
    [self setCursorVisibility];
}

- (void)didTapDeleteToken:(VENToken *)token
{
    if ([self.delegate respondsToSelector:@selector(tokenField:didDeleteTokenAtIndex:)] && [self numberOfTokens]) {
        [self.delegate tokenField:self didDeleteTokenAtIndex:[self.tokens indexOfObject:token]];
        [self setCursorVisibility];
    }
}

- (void)unhighlightAllTokens
{
    for (VENToken *token in self.tokens) {
        token.highlighted = NO;
    }
    
    [self setCursorVisibility];
}

- (void)setCursorVisibility
{
    NSArray *highlightedTokens = [self.tokens filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(VENToken *evaluatedObject, NSDictionary *bindings) {
        return evaluatedObject.highlighted;
    }]];
    
    BOOL visible = [highlightedTokens count] == 0;
    if (visible) {
        [self inputTextFieldBecomeFirstResponder];
    } else {
        [self.invisibleTextField becomeFirstResponder];
    }
}

- (void)updateInputPlaceholder
{
    BOOL shouldShowPlaceholder = YES;
    
    if (([self.inputTextField isFirstResponder] || [self.invisibleTextField isFirstResponder]) && self.tokens.count) {
        shouldShowPlaceholder = NO;
    }
    
    self.inputTextField.attributedPlaceholder = shouldShowPlaceholder ? self.attributedPlaceholder : nil;
}

- (void)focusInputTextField
{
    CGPoint contentOffset = self.scrollView.contentOffset;
    CGFloat targetY = self.inputTextField.y + [self heightForToken] - self.maxHeight;
    if (targetY > contentOffset.y) {
        CGPoint bottomOffset = CGPointMake(0, self.scrollView.contentSize.height - self.scrollView.bounds.size.height + self.scrollView.contentInset.bottom);
        [self.scrollView setContentOffset:CGPointMake(contentOffset.x, bottomOffset.y) animated:NO];
    }
}

- (VENTokenColorScheme *)colorSchemeForTokenAtIndex:(NSUInteger)index {
    
    if ([self.dataSource respondsToSelector:@selector(tokenField:colorSchemeForTokenAtIndex:)]) {
        return [self.dataSource tokenField:self colorSchemeForTokenAtIndex:index];
    }
    
    return self.colorScheme;
}

- (void)didTapDismiss:(id)sender
{
    [self.delegate tokenFieldDidTapDismiss:self];
}

#pragma mark - Data Source

- (NSString *)titleForTokenAtIndex:(NSUInteger)index
{
    return [self.dataSource tokenField:self titleForTokenAtIndex:index];
}

- (UIView *)leftViewForTokenAtIndex:(NSUInteger)index
{
    return [self.dataSource tokenField:self leftViewForTokenAtIndex:index];
}

- (NSUInteger)numberOfTokens
{
    if ([self.dataSource respondsToSelector:@selector(numberOfTokensInTokenField:)]) {
        return [self.dataSource numberOfTokensInTokenField:self];
    }
    
    return 0;
}

- (NSString *)collapsedText
{
    if ([self.dataSource respondsToSelector:@selector(tokenFieldCollapsedText:)]) {
        return [self.dataSource tokenFieldCollapsedText:self];
    }
    
    return @"";
}


#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(tokenField:didEnterText:)]) {
        if ([textField.text length]) {
            [self.delegate tokenField:self didEnterText:textField.text];
        }
    }
    
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [self updateInputPlaceholder];
    
    if (textField == self.inputTextField) {
        [self unhighlightAllTokens];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self updateInputPlaceholder];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    [self unhighlightAllTokens];
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    for (NSString *delimiter in self.delimiters) {
        if (newString.length > delimiter.length &&
            [[newString substringFromIndex:newString.length - delimiter.length] isEqualToString:delimiter]) {
            NSString *enteredString = [newString substringToIndex:newString.length - delimiter.length];
            if ([self.delegate respondsToSelector:@selector(tokenField:didEnterText:)]) {
                if (enteredString.length) {
                    [self.delegate tokenField:self didEnterText:enteredString];
                    return NO;
                }
            }
        }
    }
    return YES;
}


#pragma mark - VENBackspaceTextFieldDelegate

- (void)textFieldDidEnterBackspace:(VENBackspaceTextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(tokenField:didDeleteTokenAtIndex:)] && [self numberOfTokens]) {
        BOOL didDeleteToken = NO;
        for (VENToken *token in self.tokens) {
            if (token.highlighted) {
                [self.delegate tokenField:self didDeleteTokenAtIndex:[self.tokens indexOfObject:token]];
                didDeleteToken = YES;
                break;
            }
        }
        if (!didDeleteToken) {
            VENToken *lastToken = [self.tokens lastObject];
            lastToken.highlighted = YES;
        }
        [self setCursorVisibility];
        [self updateInputPlaceholder];
    }
}

@end
