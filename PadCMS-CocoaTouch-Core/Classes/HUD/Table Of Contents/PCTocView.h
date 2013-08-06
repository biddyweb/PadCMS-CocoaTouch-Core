//
//  PCTocView.h
//  PCTocView
//
//  Created by Maxim Pervushin on 7/30/12.
//  Copyright (c) PadCMS (http://www.padcms.net)
//
//
//  This software is governed by the CeCILL-C  license under French law and
//  abiding by the rules of distribution of free software.  You can  use,
//  modify and/ or redistribute the software under the terms of the CeCILL-C
//  license as circulated by CEA, CNRS and INRIA at the following URL
//  "http://www.cecill.info".
//
//  As a counterpart to the access to the source code and  rights to copy,
//  modify and redistribute granted by the license, users are provided only
//  with a limited warranty  and the software's author,  the holder of the
//  economic rights,  and the successive licensors  have only  limited
//  liability.
//
//  In this respect, the user's attention is drawn to the risks associated
//  with loading,  using,  modifying and/or developing or reproducing the
//  software by the user in light of its specific status of free software,
//  that may mean  that it is complicated to manipulate,  and  that  also
//  therefore means  that it is reserved for developers  and  experienced
//  professionals having in-depth computer knowledge. Users are therefore
//  encouraged to load and test the software's suitability as regards their
//  requirements in conditions enabling the security of their systems and/or
//  data to be ensured and,  more generally, to use and operate it in the
//  same conditions as regards security.
//
//  The fact that you are presently reading this means that you have had
//  knowledge of the CeCILL-C license and that you accept its terms.
//

#import <UIKit/UIKit.h>

@class PCTocView;
@class PCGridView;

/**
 @enum PCTocViewState.
 @brief The state of the PCTocView object.
 */
typedef enum _PCTocViewState {
    PCTocViewStateInvalid = -1, /// Invalid state. Used at initialization step.
    PCTocViewStateHidden = 0, /// Toc view fully hidden. Button and grid view is not visible.
    PCTocViewStateVisible = 1, /// Button is visible, grid view is hidden.
    PCTocViewStateActive = 2 /// Both button and grid view is visible.
} PCTocViewState;

/**
 @protocol PCTocViewDelegate.
 @brief Methods of the PCTocViewDelegate protocol allow the delegate to execute actions when the state of the toc is changed.
 */
@protocol PCTocViewDelegate <NSObject>

@optional
/**
 @brief Asks the delegate if the receiving toc view should transit to given state.
 @param The toc view object that making this request.
 @param The state of the toc view.
 @param Animation flag.
 @return YES if the toc view should transit to the state and NO otherwise. Default value is NO.
 */
- (BOOL)tocView:(PCTocView *)tocView transitToState:(PCTocViewState)state animated:(BOOL)animated;

@end

/**
 @class PCTocView.
 @brief An instance of PCTocView is a view that represents table of contents or summary.
 */
@interface PCTocView : UIView

/**
 @brief The object that acts as the delegate of the receiving toc view.
 */
@property (assign) id<PCTocViewDelegate> delegate;

/**
 @brief Current state of the toc view.
 */
@property (readonly, nonatomic) PCTocViewState state;

/**
 @brief An instance of the UIView that placed behind all other subviews.
 */
@property (readonly, nonatomic) UIView *backgroundView;

/**
 @brief Button that changes toc view state.
 */
@property (readonly, nonatomic) UIButton *button;

/**
 @brief preconfigured PCGridView instance that shows toc images and responds to the touches.
 */
@property (readonly, nonatomic) PCGridView *gridView;

/**
 @brief Change the receiver state.
 @param The state that should be applied.
 @param The flag indicates that the new state should be applied with or without animation.
 */
- (void)transitToState:(PCTocViewState)state animated:(BOOL)animated;

/**
 @brief Returns the center of the view for the specified state and containing view bounds.
 @param The state of the toc view object.
 @param The bounds of the container view.
 @return The CGPoint structure that specifies the center of the toc view object.
 */
- (CGPoint)centerForState:(PCTocViewState)state containerBounds:(CGRect)containerBounds;

/**
 @brief Creates and returns a new toc view object configured to be used at the top edge of the container view.
 @param The frame of the toc view.
 @return The new toc view object.
 */
+ (PCTocView *)topTocViewWithFrame:(CGRect)frame;

/**
 @brief Creates and returns a new toc view object configured to be used as the bottom edge of the container view.
 @param The frame of the toc view.
 @return The new toc view object.
 */
+ (PCTocView *)bottomTocViewWithFrame:(CGRect)frame;

@end
