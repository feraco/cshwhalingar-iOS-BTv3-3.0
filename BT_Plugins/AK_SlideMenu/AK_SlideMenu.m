/*
 *	Copyright 2014, Andy Kitts
 *
 *	All rights reserved.
 *
 *	Redistribution and use in source and binary forms, with or without modification, are 
 *	permitted provided that the following conditions are met:
 *
 *	Redistributions of source code must retain the above copyright notice which includes the
 *	name(s) of the copyright holders. It must also retain this list of conditions and the 
 *	following disclaimer. 
 *
 *	Redistributions in binary form must reproduce the above copyright notice, this list 
 *	of conditions and the following disclaimer in the documentation and/or other materials 
 *	provided with the distribution. 
 *
 *	Neither the name of David Book, or buzztouch.com nor the names of its contributors 
 *	may be used to endorse or promote products derived from this software without specific 
 *	prior written permission.
 *
 *	THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
 *	ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
 *	WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
 *	IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
 *	INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT 
 *	NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR 
 *	PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, 
 *	WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) 
 *	ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY 
 *	OF SUCH DAMAGE. 
 */


#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "JSON.h"
#import "BT_fileManager.h"
#import "BT_color.h"
#import "cshwhalingar_appDelegate.h"
#import "BT_strings.h"
#import "BT_viewUtilities.h"
#import "BT_downloader.h"
#import "BT_item.h"
#import "BT_debugger.h"
#import "AK_SlideMenu.h"
#import "MFSideMenu.h"
#import "BT_imageTools.h"
#import "LBHamburgerButton.h"

@implementation AK_SlideMenu
@synthesize menuItems, sideTableView;
@synthesize saveAsFileName, downloader, isLoading, didInit;

//viewDidLoad
-(void)viewDidLoad{
    [BT_debugger showIt:self theMessage:@"viewDidLoad"];
    [super viewDidLoad];
    [self setUpSlideMenu];
    [self setDidInit:0];
    //flag not loading
    [self setIsLoading:FALSE];
    BT_background_view * bgImageView = [[BT_background_view alloc]initWithFrame:[[UIScreen mainScreen]bounds]];
    [bgImageView updateProperties:self.screenData];
    [self.view addSubview:bgImageView];
    //build the table that holds the menu items.
    self.view.frame = [[UIScreen mainScreen]bounds];
    self.sideTableView = [[UITableView alloc]initWithFrame:[[UIScreen mainScreen] bounds] style:UITableViewStyleGrouped];
    self.sideTableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, self.sideTableView.bounds.size.width, 0.01f)];
    float height = [[UIApplication sharedApplication]statusBarFrame].size.height;
    self.sideTableView.contentInset = UIEdgeInsetsMake(height, 0.0f, 0.0f, 0.0f);
    self.sideTableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.sideTableView setDataSource:self];
    [self.sideTableView setDelegate:self];
    self.sideTableView.separatorColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:self.screenData  nameOfProperty:@"listRowSeparatorColor" defaultValue:@"#000000"]];
    self.sideTableView.separatorInset = UIEdgeInsetsZero;
    //[self.sideTableView setLayoutMargins:UIEdgeInsetsZero];
    self.sideTableView.backgroundColor = [UIColor clearColor];
    //prevent scrolling?
    if([[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"preventAllScrolling" defaultValue:@""] isEqualToString:@"1"]){
        [self.sideTableView setScrollEnabled:FALSE];
    }
    UIRefreshControl *refresh = [[UIRefreshControl alloc] init];
    refresh.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    refresh.attributedTitle = [[NSAttributedString alloc] initWithString:@"Pull to Refresh App Data"];
    [self.sideTableView addSubview:refresh];
    [self.view addSubview:sideTableView];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(eventHandler:)
     name:MFSideMenuStateNotificationEvent
     object:nil ];
    
}

-(void)setUpSlideMenu{
    cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
    BT_item *centerItem = [appDelegate.rootApp getScreenDataByItemId:[self.screenData.jsonVars objectForKey:@"homeScreenId"]];
    BT_viewController *center = [appDelegate.rootApp getViewControllerForScreen:centerItem];
    BT_navController *rootNavController = [[BT_navController alloc] initWithRootViewController:center];
    MFSideMenuContainerViewController *container = [MFSideMenuContainerViewController
                                                    containerWithCenterViewController:(BT_viewController*)rootNavController
                                                    leftMenuViewController:Nil
                                                    rightMenuViewController:Nil];
    container.leftMenuViewController = self;
    container.panMode = MFSideMenuPanModeDefault;
    container.view.autoresizesSubviews = YES;
    if ([[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"menuShadow" defaultValue:@"1"]integerValue] == 1) {
        container.shadow.color = [UIColor blackColor];
    }else{
        container.shadow.color = [UIColor clearColor];
    }
    float menuWidth = 0;
    if (appDelegate.rootDevice.isIPad) {
        menuWidth = [[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"menuWidthLargeDevice" defaultValue:@"270"]floatValue];
    }else{
        menuWidth = [[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"menuWidthSmallDevice" defaultValue:@"270"]floatValue];
    }
    container.leftMenuWidth = menuWidth;
    [appDelegate.rootApp setRootNavController:rootNavController];
    [appDelegate.window setRootViewController:container];
    [appDelegate.window bringSubviewToFront:[container.centerViewController view]];
    [container.centerViewController.view addSubview:appDelegate.rootApp.rootBackgroundView];
    [container.centerViewController.view sendSubviewToBack:appDelegate.rootApp.rootBackgroundView];
}


//view will appear
-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [BT_debugger showIt:self theMessage:@"viewWillAppear"];
    
    //if we have not yet inited data..
    if(self.didInit == 0){
        [self performSelector:(@selector(loadData)) withObject:nil afterDelay:0.1];
        [self setDidInit:1];
    }
    
    cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
    NSString * homeId = [self.screenData.jsonVars objectForKey:@"homeScreenId"];
    if (homeId.length > 10) {
        BT_item * loadFirst = [appDelegate.rootApp getScreenDataByItemId:homeId];
        //[loadFirst setIsHomeScreen:YES];
        BT_navController *navigationController = (BT_navController*)self.menuContainerViewController.centerViewController;
        NSArray *controllers = [NSArray arrayWithObject:[appDelegate.rootApp getViewControllerForScreen:loadFirst]];
        navigationController.viewControllers = controllers;
    }
}


//load data
-(void)loadData{
    [BT_debugger showIt:self theMessage:@"loadData"];
    self.isLoading = TRUE;
    
    //prevent interaction during operation
    [sideTableView setScrollEnabled:FALSE];
    [sideTableView setAllowsSelection:FALSE];
    
    /*
     Screen Data scenarios
     --------------------------------
     a)	No dataURL is provided in the screen data - use the info configured in the app's configuration file
     b)	A dataURL is provided, download now if we don't have a cache, else, download on refresh.
     */
    
    self.saveAsFileName = [NSString stringWithFormat:@"screenData_%@.txt", [self.screenData itemId]];
    
    //do we have a URL?
    BOOL haveURL = FALSE;
    if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""] length] > 10){
        haveURL = TRUE;
    }
    
    //start by filling the list from the configuration file, use these if we can't get anything from a URL
    if([[self.screenData jsonVars] objectForKey:@"childItems"]){
        
        //init the items array
        self.menuItems = [[NSMutableArray alloc] init];
        
        NSArray *tmpMenuItems = [[self.screenData jsonVars] objectForKey:@"childItems"];
        for(NSDictionary *tmpMenuItem in tmpMenuItems){
            BT_item *thisMenuItem = [[BT_item alloc] init];
            thisMenuItem.itemId = [tmpMenuItem objectForKey:@"itemId"];
            thisMenuItem.itemType = [tmpMenuItem objectForKey:@"itemType"];
            thisMenuItem.jsonVars = tmpMenuItem;
            [self.menuItems addObject:thisMenuItem];
        }
        
    }
    
    //if we have a URL, fetch..
    if(haveURL){
        
        //look for a previously cached version of this screens data...
        if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
            [BT_debugger showIt:self theMessage:@"parsing cached version of screen data"];
            NSString *staleData = [BT_fileManager readTextFileFromCacheWithEncoding:[self saveAsFileName] encodingFlag:-1];
            [self parseScreenData:staleData];
        }else{
            [BT_debugger showIt:self theMessage:@"no cached version of this screens data available."];
            [self downloadData];
        }
        
        
    }else{
        
        //show the child items in the config data
        [BT_debugger showIt:self theMessage:@"using menu items from the screens configuration data."];
        [self layoutScreen];
        
    }
    
}

//download data
-(void)downloadData{
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"downloading screen data from: %@", [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""]]];
    
    //flag this as the current screen
    cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
    appDelegate.rootApp.currentScreenData = self.screenData;
    
    //prevent interaction during operation
    [sideTableView setScrollEnabled:FALSE];
    [sideTableView setAllowsSelection:FALSE];
    
    //show progress
    [self showProgress];
    
    NSString *tmpURL = @"";
    if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""] length] > 3){
        
        //merge url variables
        tmpURL = [BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@""];
        
        ///merge possible variables in URL
        NSString *useURL = [BT_strings mergeBTVariablesInString:tmpURL];
        NSString *escapedUrl = [useURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        //fire downloader to fetch and results
        downloader = [[BT_downloader alloc] init];
        [downloader setSaveAsFileName:[self saveAsFileName]];
        [downloader setSaveAsFileType:@"text"];
        [downloader setUrlString:escapedUrl];
        [downloader setDelegate:self];
        [downloader downloadFile];
    }
}

//parse screen data
-(void)parseScreenData:(NSString *)theData{
    [BT_debugger showIt:self theMessage:@"parseScreenData"];
    
    //prevent interaction during operation
    [sideTableView setScrollEnabled:FALSE];
    [sideTableView setAllowsSelection:FALSE];
    
    @try {
        
        //arrays for screenData
        self.menuItems = [[NSMutableArray alloc] init];
        
        //create dictionary from the JSON string
        SBJsonParser *parser = [SBJsonParser new];
        id jsonData = [parser objectWithString:theData];
        
        
        if(!jsonData){
            
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"ERROR parsing JSON: %@", parser.errorTrace]];
            [self showAlert:NSLocalizedString(@"errorTitle",@"~ Error ~") theMessage:NSLocalizedString(@"appParseError", @"There was a problem parsing some configuration data. Please make sure that it is well-formed") alertTag:0];
            [BT_fileManager deleteFile:[self saveAsFileName]];
            
        }else{
            
            if([jsonData objectForKey:@"childItems"]){
                NSArray *tmpMenuItems = [jsonData objectForKey:@"childItems"];
                for(NSDictionary *tmpMenuItem in tmpMenuItems){
                    BT_item *thisMenuItem = [[BT_item alloc] init];
                    thisMenuItem.itemId = [tmpMenuItem objectForKey:@"itemId"];
                    thisMenuItem.itemType = [tmpMenuItem objectForKey:@"itemType"];
                    thisMenuItem.jsonVars = tmpMenuItem;
                    [self.menuItems addObject:thisMenuItem];
                }
            }
            
            //layout screen
            [self layoutScreen];
            
        }
        
    }@catch (NSException * e) {
        
        //delete bogus data, show alert
        [BT_fileManager deleteFile:[self saveAsFileName]];
        [self showAlert:NSLocalizedString(@"errorTitle",@"~ Error ~") theMessage:NSLocalizedString(@"appParseError", @"There was a problem parsing some configuration data. Please make sure that it is well-formed") alertTag:0];
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"error parsing screen data: %@", e]];
        
    }
    
}

//build screen
-(void)layoutScreen{
    [BT_debugger showIt:self theMessage:@"layoutScreen"];
    
    //if we did not have any menu items...
    if(self.menuItems.count < 1){
        
        for(int i = 0; i < 5; i++){
            
            //create a menu item from the data
            BT_item *thisMenuItemData = [[BT_item alloc] init];
            [thisMenuItemData setJsonVars:nil];
            [thisMenuItemData setItemId:@""];
            [thisMenuItemData setItemType:@"BT_menuItem"];
            [self.menuItems addObject:thisMenuItemData];
            
        }
        
        //show message
        //[self showAlert:nil:NSLocalizedString(@"noListItems",@"This menu has no list items?"):0];
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"%@",NSLocalizedString(@"noListItems",@"This menu has no list items?")]];
        
    }
    
    //enable interaction again (unless owner turned it off)
    if([[BT_strings getStyleValueForScreen:self.screenData nameOfProperty:@"preventAllScrolling" defaultValue:@""] isEqualToString:@"1"]){
        [self.sideTableView setScrollEnabled:FALSE];
    }else{
        [sideTableView setScrollEnabled:TRUE];
    }
    [sideTableView setAllowsSelection:TRUE];
    
    
    //reload table
    [self.sideTableView reloadData];
    
    //flag done loading
    self.isLoading = FALSE;
    cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
    BT_item * loadFirst = [appDelegate.rootApp getScreenDataByItemId:[[[self.menuItems
                                                                        objectAtIndex:0]
                                                                       jsonVars] objectForKey:@"loadScreenWithItemId"]];
    BT_navController *navigationController = (BT_navController*)self.menuContainerViewController.centerViewController;
    NSArray *controllers = [NSArray arrayWithObject:[appDelegate.rootApp getViewControllerForScreen:loadFirst]];
    navigationController.viewControllers = controllers;
    
}


//////////////////////////////////////////////////////////////
//UITableView delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// number of rows
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.menuItems count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.rootDevice.isIPad) {
        return [[BT_strings getStyleValueForScreen:self.screenData  nameOfProperty:@"listRowHeightLargeDevice" defaultValue:@"100"]floatValue];
    }else{
        return [[BT_strings getStyleValueForScreen:self.screenData  nameOfProperty:@"listRowHeightSmallDevice" defaultValue:@"50"]floatValue];
    }
}

//table view cells
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *CellIdentifier = [NSString stringWithFormat:@"cell_%i", indexPath.row];
    UITableViewCell *cell = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        if ([[self.screenData.jsonVars objectForKey:@"listRowSelectionStyle"] isEqualToString:@"blue"]) {
            cell.selectionStyle = UITableViewCellSelectionStyleBlue;
        }else if ([[self.screenData.jsonVars objectForKey:@"listRowSelectionStyle"] isEqualToString:@"gray"]){
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
        }else{
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        cell.backgroundColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:self.screenData  nameOfProperty:@"listRowBackgroundColor" defaultValue:@"#FFFFFF"]];
        UIColor *fontColor = [BT_color getColorFromHexString:[BT_strings getStyleValueForScreen:self.screenData  nameOfProperty:@"listTitleFontColor" defaultValue:@"#000000"]];
        cell.textLabel.textColor = fontColor;
        cell.detailTextLabel.textColor = fontColor;
        [cell setSeparatorInset:UIEdgeInsetsZero];
        //[cell setLayoutMargins:UIEdgeInsetsZero];
        if (appDelegate.rootDevice.isIPad) {
            [cell.textLabel setFont:[UIFont systemFontOfSize:[[BT_strings getStyleValueForScreen:self.screenData  nameOfProperty:@"listTitleFontSizeLargeDevice" defaultValue:@"60"]floatValue]]];
        }else{
             [cell.textLabel setFont:[UIFont systemFontOfSize:[[BT_strings getStyleValueForScreen:self.screenData  nameOfProperty:@"listTitleFontSizeSmallDevice" defaultValue:@"30"]floatValue]]];
        }
        
    }
    //this menu item
    BT_item *thisMenuItemData = [self.menuItems objectAtIndex:indexPath.row];
    cell.textLabel.text = [thisMenuItemData.jsonVars objectForKey:@"titleText"];
    
    
    cell.imageView.image = [self getImage:[thisMenuItemData.jsonVars objectForKey:@"imageName"]];
    cell.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    //cell.detailTextLabel.text = [thisMenuItemData.jsonVars objectForKey:@"loadScreenWithItemId"];
    //return
    return cell;
}

//on row select
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"didSelectRowAtIndexPath: Selected Row: %i", indexPath.row]];
    
    //pass this menu item to the tapForMenuItem method
    BT_item *thisMenuItem = [self.menuItems objectAtIndex:indexPath.row];
    if([thisMenuItem jsonVars] != nil){
        
        //appDelegate
        cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
        
        //get possible itemId of the screen to load
        NSString *loadScreenItemId = [BT_strings getJsonPropertyValue:thisMenuItem.jsonVars nameOfProperty:@"loadScreenWithItemId" defaultValue:@""];
        
        //get possible nickname of the screen to load
        NSString *loadScreenNickname = [BT_strings getJsonPropertyValue:thisMenuItem.jsonVars nameOfProperty:@"loadScreenWithNickname" defaultValue:@""];
        
        //bail if load screen = "none"
        if([loadScreenItemId isEqualToString:@"none"]){
            return;
        }
        
        //check for loadScreenWithItemId THEN loadScreenWithNickname THEN loadScreenObject
        BT_item *screenObjectToLoad = nil;
        if([loadScreenItemId length] > 1){
            screenObjectToLoad = [appDelegate.rootApp getScreenDataByItemId:loadScreenItemId];
        }else{
            if([loadScreenNickname length] > 1){
                screenObjectToLoad = [appDelegate.rootApp getScreenDataByNickname:loadScreenNickname];
            }else{
                if([thisMenuItem.jsonVars objectForKey:@"loadScreenObject"]){
                    screenObjectToLoad = [[BT_item alloc] init];
                    [screenObjectToLoad setItemId:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemId"]];
                    [screenObjectToLoad setItemNickname:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemNickname"]];
                    [screenObjectToLoad setItemType:[[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"] objectForKey:@"itemType"]];
                    [screenObjectToLoad setJsonVars:[thisMenuItem.jsonVars objectForKey:@"loadScreenObject"]];
                }
            }
        }
        
        
        //load next screen if it's not nil
        if(screenObjectToLoad != nil){
            if (appDelegate.rootApp.currentScreenData != screenObjectToLoad) {
                BT_navController *navigationController = (BT_navController*)self.menuContainerViewController.centerViewController;
                NSArray *controllers = [NSArray arrayWithObject:[appDelegate.rootApp getViewControllerForScreen:screenObjectToLoad]];
                navigationController.viewControllers = controllers;
            }
            [self.menuContainerViewController setMenuState:MFSideMenuStateClosed];
        }else{
            //show message
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this click?")]];
        }
        
    }else{
        
        //show message
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"%@",NSLocalizedString(@"menuTapError",@"The application doesn't know how to handle this action?")]];
        
    }
    
}

//////////////////////////////////////////////////////////////////////////////////////////////////
//downloader delegate methods
-(void)downloadFileStarted:(NSString *)message{
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"downloadFileStarted: %@", message]];
}
-(void)downloadFileInProgress:(NSString *)message{
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"downloadFileInProgress: %@", message]];
    if(self.progressView != nil){
        UILabel *tmpLabel = (UILabel *)[self.progressView.subviews objectAtIndex:2];
        [tmpLabel setText:message];
    }
}
-(void)downloadFileCompleted:(NSString *)message{
    [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"downloadFileCompleted: %@", message]];
    [self hideProgress];
    
    //if message contains "error", look for previously cached data...
    if([message rangeOfString:@"ERROR-1968" options:NSCaseInsensitiveSearch].location != NSNotFound){
        [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"download error: There was a problem downloading data from the internet.%@", message]];
        //NSLog(@"Message: %@", message);
        
        //show alert
        [self showAlert:nil theMessage:NSLocalizedString(@"downloadError", @"There was a problem downloading some data. Check your internet connection then try again.") alertTag:0];
        
        //show local data if it exists
        if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
            
            //use stale data if we have it
            NSString *staleData = [BT_fileManager readTextFileFromCacheWithEncoding:self.saveAsFileName encodingFlag:-1];
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"building screen from stale configuration data: %@", [self saveAsFileName]]];
            [self parseScreenData:staleData];
            
        }else{
            
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"There is no local data availalbe for this screen?%@", @""]];
            
            //if we have items... else.. show alert
            if(self.menuItems.count > 0){
                [self layoutScreen];
            }
            
        }
        
        
    }else{
        
        //parse previously saved data
        if([BT_fileManager doesLocalFileExist:[self saveAsFileName]]){
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"parsing downloaded screen data.%@", @""]];
            NSString *downloadedData = [BT_fileManager readTextFileFromCacheWithEncoding:[self saveAsFileName] encodingFlag:-1];
            [self parseScreenData:downloadedData];
            
        }else{
            [BT_debugger showIt:self theMessage:[NSString stringWithFormat:@"Error caching downloaded file: %@", [self saveAsFileName]]];
            [self layoutScreen];
            
            //show alert
            [self showAlert:nil theMessage:NSLocalizedString(@"appDownloadError", @"There was a problem saving some data downloaded from the internet.") alertTag:0];
            
        }
        
    }	
    
}

//allows us to check to see if we pulled-down to refresh
-(void)scrollViewWillBeginDecelerating:(UIScrollView *)scrollView{
    [self checkIsLoading];
}
-(void)checkIsLoading{
    cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
    if(isLoading){
        return;
    }else{
        //how far down did we pull?
        double down = sideTableView.contentOffset.y;
        if(down <= -120){
            //if([[BT_strings getJsonPropertyValue:self.screenData.jsonVars nameOfProperty:@"dataURL" defaultValue:@"1"] length] > 3){
            [appDelegate refreshAppData];
            
            //}
        }
    }
}

-(UIImage*)getImage:(NSString *)imageLocation {
    UIImage *tmpImage = nil;
    
    
    //check if this is from a URL or not
    NSString *http = [imageLocation substringToIndex:4];
    if ([[http uppercaseString] isEqualToString:@"HTTP"]) {
        tmpImage = [[UIImage alloc]init];
        NSString *imageName = [BT_strings getFileNameFromURL:imageLocation];
        if ([BT_fileManager doesLocalFileExist:imageName]) tmpImage = [BT_fileManager getImageFromFile:imageName];
        else {
            tmpImage = [BT_imageTools getImageFromURL:imageLocation];
            [BT_fileManager saveImageToFile:tmpImage fileName:imageName];
        }
    }
    else {
        if ([BT_fileManager doesFileExistInBundle:imageLocation]) {
            tmpImage = [[UIImage alloc]init];
            tmpImage = [UIImage imageNamed:imageLocation];
        }
    }
    return tmpImage;
}

+ (UIBarButtonItem *)hamburgerBarButtonItem {
    cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
    LBHamburgerButton *hamburgerButton = [[LBHamburgerButton alloc] initWithFrame:CGRectMake(0, 0, 50, 50)
                                                                withHamburgerType:LBHamburgerButtonTypeBackButton
                                                                   hamburgerState:LBHamburgerButtonStateNotHamburger
                                                                        lineWidth:20
                                                                       lineHeight:20/6
                                                                      lineSpacing:20/6
                                                                       lineCenter:CGPointMake(10, 25)
                                                                            color:appDelegate.rootApp.rootNavController.navigationBar.tintColor];
    hamburgerButton.tag = 123;
    [hamburgerButton setBackgroundColor:[UIColor clearColor]];
    [hamburgerButton addTarget:[AK_SlideMenu class] action:@selector(buttonPressed:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *hamburgerBtn = [[UIBarButtonItem alloc] initWithCustomView:hamburgerButton];
    return hamburgerBtn;
}

+ (void)buttonPressed:(id)sender {
    cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
    LBHamburgerButton* btn = (LBHamburgerButton*)[[appDelegate getViewController].navigationController.view viewWithTag:123];
    [btn switchState];
    [[[appDelegate getViewController] menuContainerViewController] toggleLeftSideMenuCompletion:^{}];
}

-(void)eventHandler: (NSNotification *) notification
{
    
    cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
    LBHamburgerButton* btn = (LBHamburgerButton*)[[appDelegate getViewController].navigationController.view viewWithTag:123];
    if ([[notification.userInfo objectForKey:@"eventType"] integerValue] == MFSideMenuStateEventMenuWillOpen){
        [btn switchOpen];
    }
    
    if ([[notification.userInfo objectForKey:@"eventType"] integerValue] == MFSideMenuStateEventMenuWillClose) {
        [btn switchClose];
    }
}

+(void)closeHamburger{
    cshwhalingar_appDelegate *appDelegate = (cshwhalingar_appDelegate *)[[UIApplication sharedApplication] delegate];
    LBHamburgerButton* btn = (LBHamburgerButton*)[[appDelegate getViewController].navigationController.view viewWithTag:123];
    [btn switchClose];
}


@end








