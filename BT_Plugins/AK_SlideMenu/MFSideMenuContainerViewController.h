//
//  MFSideMenuContainerViewController.h
//  MFSideMenuDemoSplitViewController
//
//  Created by Michael Frederick on 4/2/13.
//  Copyright (c) 2013 Frederick Development. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MFSideMenuShadow.h"

extern NSString * const MFSideMenuStateNotificationEvent;

typedef enum {
    MFSideMenuPanModeNone = 0, // pan disabled
    MFSideMenuPanModeCenterViewController = 1 << 0, // enable panning on the centerViewController
    MFSideMenuPanModeSideMenu = 1 << 1, // enable panning on side menus
    MFSideMenuPanModeDefault = MFSideMenuPanModeCenterViewController | MFSideMenuPanModeSideMenu
} MFSideMenuPanMode;

typedef enum {
    MFSideMenuStateClosed, // the menu is closed
    MFSideMenuStateLeftMenuOpen, // the left-hand menu is open
    MFSideMenuStateRightMenuOpen // the right-hand menu is open
} MFSideMenuState;

typedef enum {
    MFSideMenuStateEventMenuWillOpen, // the menu is going to open
    MFSideMenuStateEventMenuDidOpen, // the menu finished opening
    MFSideMenuStateEventMenuWillClose, // the menu is going to close
    MFSideMenuStateEventMenuDidClose // the menu finished closing
} MFSideMenuStateEvent;


@interface MFSideMenuContainerViewController : BT_viewController<UIGestureRecognizerDelegate>

+ (MFSideMenuContainerViewController *)containerWithCenterViewController:(BT_viewController*)centerViewController
                                                  leftMenuViewController:(BT_viewController*)leftMenuViewController
                                                 rightMenuViewController:(BT_viewController*)rightMenuViewController;

@property (nonatomic, strong) BT_viewController *centerViewController;
@property (nonatomic, strong) BT_viewController *leftMenuViewController;
@property (nonatomic, strong) BT_viewController *rightMenuViewController;

@property (nonatomic, assign) MFSideMenuState menuState;
@property (nonatomic, assign) MFSideMenuPanMode panMode;

// menu open/close animation duration -- user can pan faster than default duration, max duration sets the limit
@property (nonatomic, assign) CGFloat menuAnimationDefaultDuration;
@property (nonatomic, assign) CGFloat menuAnimationMaxDuration;

// width of the side menus
@property (nonatomic, assign) CGFloat menuWidth;
@property (nonatomic, assign) CGFloat leftMenuWidth;
@property (nonatomic, assign) CGFloat rightMenuWidth;

// shadow
@property (nonatomic, strong) MFSideMenuShadow *shadow;

// menu slide-in animation
@property (nonatomic, assign) BOOL menuSlideAnimationEnabled;
@property (nonatomic, assign) CGFloat menuSlideAnimationFactor; // higher = less menu movement on animation


- (void)toggleLeftSideMenuCompletion:(void (^)(void))completion;
- (void)toggleRightSideMenuCompletion:(void (^)(void))completion;
- (void)setMenuState:(MFSideMenuState)menuState completion:(void (^)(void))completion;
- (void)setMenuWidth:(CGFloat)menuWidth animated:(BOOL)animated;
- (void)setLeftMenuWidth:(CGFloat)leftMenuWidth animated:(BOOL)animated;
- (void)setRightMenuWidth:(CGFloat)rightMenuWidth animated:(BOOL)animated;

// can be used to attach a pan gesture recognizer to a custom view
- (UIPanGestureRecognizer *)panGestureRecognizer;

@end