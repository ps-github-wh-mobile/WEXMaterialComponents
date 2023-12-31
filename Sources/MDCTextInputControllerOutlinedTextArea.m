// Copyright 2017-present the Material Components for iOS authors. All Rights Reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "MDCTextInputControllerOutlinedTextArea.h"

#import "MDCTextInput.h"
#import "MDCTextInputBorderView.h"
#import "MDCTextInputControllerBase.h"
#import "MDCTextInputUnderlineView.h"
#import "MDCTextInputControllerBase+Subclassing.h"

#import "MaterialMath.h"

/**
 Note: Right now this is a subclass of MDCTextInputControllerBase since they share a vast
 majority of code. If the designs diverge further, this would make a good candidate for its own
 class.
 */

#pragma mark - Constants

static const CGFloat MDCTextInputTextFieldOutlinedTextAreaFullPadding = 16;
static const CGFloat MDCTextInputTextFieldOutlinedTextAreaHalfPadding = 8;

// The guidelines have 8 points of padding but since the fonts on iOS are slightly smaller, we need
// to add points to keep the versions at the same height.
static const CGFloat MDCTextInputTextFieldOutlinedTextAreaPaddingAdjustment = 1;
static const NSUInteger MDCTextInputTextFieldOutlinedTextAreaMinimumLines = 5;
static const BOOL MDCTextInputTextFieldOutlinedTextAreaExpandsOnOverflow = NO;

#pragma mark - Class Properties

static UIRectCorner _roundedCornersDefault = UIRectCornerAllCorners;

@interface MDCTextInputControllerOutlinedTextArea ()

@property(nonatomic, strong) NSLayoutConstraint *placeholderTop;

@end

@implementation MDCTextInputControllerOutlinedTextArea

- (instancetype)initWithTextInput:(UIView<MDCTextInput> *)input {
  NSAssert([input conformsToProtocol:@protocol(MDCMultilineTextInput)],
           @"This design is meant for multi-line text fields only.");
  self = [super initWithTextInput:input];
  if (self) {
    super.expandsOnOverflow = MDCTextInputTextFieldOutlinedTextAreaExpandsOnOverflow;
    super.minimumLines = MDCTextInputTextFieldOutlinedTextAreaMinimumLines;
  }
  return self;
}

#pragma mark - Properties Implementations

- (BOOL)isFloatingEnabled {
  return YES;
}

- (void)setFloatingEnabled:(__unused BOOL)floatingEnabled {
  // Unused. Floating is always enabled.
}

+ (UIRectCorner)roundedCornersDefault {
  return _roundedCornersDefault;
}

+ (void)setRoundedCornersDefault:(UIRectCorner)roundedCornersDefault {
  _roundedCornersDefault = roundedCornersDefault;
}

#pragma mark - MDCTextInputPositioningDelegate

// clang-format off
/**
 textInsets: is the source of truth for vertical layout. It's used to figure out the proper
 height and also where to place the placeholder / text field.

 NOTE: It's applied before the textRect is flipped for RTL. So all calculations are done here à la
 LTR.

 The vertical layout is, at most complex, this form:

 MDCTextInputTextFieldOutlinedTextAreaHalfPadding +                   // Small padding
 MDCTextInputTextFieldOutlinedTextAreaPaddingAdjustment               // Additional point (iOS specific)
 placeholderEstimatedHeight                                           // Height of placeholder
 MDCTextInputTextFieldOutlinedTextAreaHalfPadding +                   // Small padding
 MDCTextInputTextFieldOutlinedTextAreaPaddingAdjustment               // Additional point (iOS specific)
 ceil(MAX(self.textInput.font.lineHeight,                          // Text field or placeholder
             self.textInput.placeholderLabel.font.lineHeight))
 underlineOffset                                                      // Small Padding +
                                                                      // underlineLabelsOffset From super class.
 */
// clang-format on
- (UIEdgeInsets)textInsets:(UIEdgeInsets)defaultInsets
    withSizeThatFitsWidthHint:(CGFloat)widthHint {
  defaultInsets.left = MDCTextInputTextFieldOutlinedTextAreaFullPadding;
  defaultInsets.right = MDCTextInputTextFieldOutlinedTextAreaFullPadding;
  UIEdgeInsets textInsets = [super textInsets:defaultInsets withSizeThatFitsWidthHint:widthHint];
  textInsets.top = MDCTextInputTextFieldOutlinedTextAreaHalfPadding +
                   MDCTextInputTextFieldOutlinedTextAreaPaddingAdjustment +
                   rint(self.textInput.placeholderLabel.font.lineHeight *
                        (CGFloat)self.floatingPlaceholderScale.floatValue) +
                   MDCTextInputTextFieldOutlinedTextAreaHalfPadding +
                   MDCTextInputTextFieldOutlinedTextAreaPaddingAdjustment;

  // .bottom = underlineOffset + the half padding above the line but below the text field and any
  // space needed for the labels and / or line.
  // Legacy has an additional half padding here but this version does not.
  CGFloat underlineOffset = [self underlineOffsetWithInsets:defaultInsets widthHint:widthHint];

  textInsets.bottom = underlineOffset;

  return textInsets;
}

#pragma mark - Layout

- (void)updateBorder {
  [super updateBorder];
  UIColor *borderColor = self.textInput.isEditing ? self.activeColor : self.normalColor;
  self.textInput.borderView.borderStrokeColor =
      (self.isDisplayingCharacterCountError || self.isDisplayingErrorText) ? self.errorColor
                                                                           : borderColor;
  self.textInput.borderView.borderPath.lineWidth = self.textInput.isEditing ? 2 : 1;
  [self.textInput.borderView setNeedsLayout];
}

- (void)updateLayout {
  [super updateLayout];

  if (!self.textInput) {
    return;
  }

  NSAssert([self.textInput conformsToProtocol:@protocol(MDCMultilineTextInput)],
           @"This design is meant for multi-line text fields only.");
  if (![self.textInput conformsToProtocol:@protocol(MDCMultilineTextInput)]) {
    return;
  }

  self.textInput.underline.alpha = 0;

  if (!self.placeholderTop) {
    self.placeholderTop =
        [NSLayoutConstraint constraintWithItem:self.textInput.placeholderLabel
                                     attribute:NSLayoutAttributeTop
                                     relatedBy:NSLayoutRelationEqual
                                        toItem:self.textInput
                                     attribute:NSLayoutAttributeTop
                                    multiplier:1
                                      constant:MDCTextInputTextFieldOutlinedTextAreaFullPadding];
    self.placeholderTop.priority = UILayoutPriorityDefaultHigh;
    self.placeholderTop.active = YES;
  }
}

// The measurement from bottom to underline center Y.
- (CGFloat)underlineOffsetWithInsets:(UIEdgeInsets)insets widthHint:(CGFloat)widthHint {
  // The amount of space underneath the underline depends on whether there is content in the
  // underline labels.
  CGFloat underlineLabelsOffset = 0;
  CGFloat scale = UIScreen.mainScreen.scale;

  if (self.textInput.leadingUnderlineLabel.text.length) {
    underlineLabelsOffset =
        ceil(self.textInput.leadingUnderlineLabel.font.lineHeight * scale) / scale;
    underlineLabelsOffset =
        MAX(underlineLabelsOffset,
            [MDCTextInputControllerBase
                calculatedNumberOfLinesForLeadingLabel:self.textInput.leadingUnderlineLabel
                                    givenTrailingLabel:self.textInput.trailingUnderlineLabel
                                                insets:insets
                                             widthHint:widthHint] *
                underlineLabelsOffset);
  }
  if (self.textInput.trailingUnderlineLabel.text.length || self.characterCountMax) {
    underlineLabelsOffset =
        MAX(underlineLabelsOffset,
            ceil(self.textInput.trailingUnderlineLabel.font.lineHeight * scale) / scale);
  }

  CGFloat underlineOffset = underlineLabelsOffset;
  underlineOffset += MDCTextInputTextFieldOutlinedTextAreaHalfPadding;

  if (!MDCCGFloatEqual(underlineLabelsOffset, 0)) {
    underlineOffset += MDCTextInputTextFieldOutlinedTextAreaHalfPadding;
  }

  return underlineOffset;
}

@end
