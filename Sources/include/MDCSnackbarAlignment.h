// Copyright 2018-present the Material Components for iOS authors. All Rights Reserved.
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

#import <Foundation/Foundation.h>

/**
 States used to configure Snackbar's horizontal alignment.
 */
typedef NS_ENUM(NSInteger, MDCSnackbarHorizontalAlignment) {
  /**
   Snackbar is positioned in the center of the screen horizontally.
   */
  MDCSnackbarHorizontalAlignmentCenter = 0,

  /**
   Snackbar is positioned near the leading margin horizontally.
   */
  MDCSnackbarHorizontalAlignmentLeading = 1,
};

/**
 States used to configure Snackbar's vertical alignment.
 */
typedef NS_ENUM(NSInteger, MDCSnackbarVerticalAlignment) {
  /**
   Snackbar is positioned on the bottom of the screen vertically.
   */
  MDCSnackbarVerticalAlignmentBottom = 0,

  /**
   Snackbar is positioned on the top of the screen vertically.
   */
  MDCSnackbarVerticalAlignmentTop = 1,
};
