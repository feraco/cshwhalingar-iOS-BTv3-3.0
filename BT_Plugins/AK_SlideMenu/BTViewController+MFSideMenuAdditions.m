//
//  UIViewController+MFSideMenuAdditions.m
//  MFSideMenuDemoBasic
//
//  Created by Michael Frederick on 4/2/13.
//  Copyright (c) 2013 Frederick Development. All rights reserved.
//

#import "BTViewController+MFSideMenuAdditions.h"
#import "MFSideMenuContainerViewController.h"

@implementation BT_viewController (MFSideMenuAdditions)

@dynamic menuContainerViewController;

- (MFSideMenuContainerViewController *)menuContainerViewController {
    id containerView = self;
    while (![containerView isKindOfClass:[MFSideMenuContainerViewController class]] && containerView) {
        if ([containerView respondsToSelector:@selector(parentViewController)])
            containerView = [containerView parentViewController];
        if ([containerView respondsToSelector:@selector(splitViewController)] && !containerView)
            containerView = [containerView splitViewController];
    }
    return containerView;
}

@end