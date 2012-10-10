//
//  RevisionViewController.m
//  PadCMS-CocoaTouch-Core
//
//  Created by Alexey Igoshev on 7/4/12.
//  Copyright (c) 2012 Adyax. All rights reserved.
//

#import "RevisionViewController.h"

#import "AbstractBasePageViewController.h"
#import "EasyTableView.h"
#import "GalleryViewController.h"
#import "ImageCache.h"
#import "InAppPurchases.h"
#import "PCFacebookViewController.h"
#import "PCGridView.h"
#import "PCLocalizationManager.h"
#import "PCMagazineViewControllersFactory.h"
#import "PCPage.h"
#import "PCPageViewController.h"
#import "PCResourceCache.h"
#import "PCScrollView.h"
#import "PCSummaryView.h"
#import "PCTocView.h"
#import "PCVideoManager.h"
#import "PCView.h"
#import "PCConfig.h"

@interface RevisionViewController ()
{
    BOOL _previewMode;
    NSUInteger _horizontalPageIndex;
    PCHudController *_hudController;
    PCShareView *_shareView;
    PCFacebookViewController *_facebookViewController;
    PCTwitterNewController *_twitterController;
    PCEmailController *_emailController;
    PCEmailController *_emailToMagazineController;
	UIInterfaceOrientation _currentInterfaceOrientation;
    PCSubscriptionMenuViewController *_subscriptionsMenuController;
    UIPopoverController *_popoverController;
	CGRect bufferBound;
}

@property (nonatomic, retain) PCScrollView* contentScrollView;
@property (nonatomic, readonly) PCPage* initialPage;

- (void)createHud;
- (void)tapGesture:(UIGestureRecognizer *)recognizer;
- (void)dismiss;

@end

@implementation RevisionViewController
@synthesize delegate;
@synthesize revision = _revision;
@synthesize contentScrollView=_contentScrollView;
@synthesize currentPageViewController=_currentPageViewController;
@synthesize nextPageViewController=_nextPageViewController;
@synthesize initialPage = _initialPage;
@synthesize topSummaryView;

- (id)initWithRevision:(PCRevision *)revision
       withInitialPage:(PCPage*)initialPage
           previewMode:(BOOL)previewMode
{
	self = [super init];
    
    if (self) {
        _revision = [revision retain];
        _horizontalPageIndex = 0;
        _previewMode = previewMode;

        if (initialPage == nil) {
            if (_revision.alternativeCoverPage && UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])) {
                _initialPage = [_revision.alternativeCoverPage retain];
            } else {
                _initialPage = [_revision.coverPage retain];
            }
        } else {
            _initialPage = [initialPage retain];
        }

		[[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(deviceOrientationDidChange:)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
        
        _contentScrollView = nil;
        _shareView = nil;
        _facebookViewController = nil;
        _twitterController = nil;
        _emailController = nil;
        _emailToMagazineController = nil;
		_currentInterfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
        _subscriptionsMenuController = nil;
        _popoverController = nil;
    }
    
    return self;
}

-(void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
	[topSummaryView release];

    if (_contentScrollView != nil) {
        [_contentScrollView release], _contentScrollView = nil;
    }

	[_initialPage release], _initialPage = nil;
	[super dealloc];
}

- (void)createHud
{
    _hudController = [[PCHudController alloc] init];
    _hudController.revision = _revision;
    _hudController.previewMode = _previewMode;
    _hudController.delegate = self;
    _hudController.hudView.frame = self.view.bounds;
    _hudController.hudView.autoresizingMask = UIViewAutoresizingFlexibleWidth |
    UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:_hudController.hudView];
    [_hudController update];
}

- (void)viewDidLoad
{
    UIViewController *viewController = [[UIViewController alloc] init];
    [self presentModalViewController:viewController animated:NO];
    [self dismissModalViewControllerAnimated:NO];
    [viewController release];
    
    [super viewDidLoad];
	_contentScrollView = [[PCScrollView alloc] initWithFrame:self.view.bounds];
	_contentScrollView.pagingEnabled = YES;
	_contentScrollView.backgroundColor = [UIColor whiteColor];
	_contentScrollView.showsVerticalScrollIndicator = NO;
	_contentScrollView.showsHorizontalScrollIndicator = NO;
	_contentScrollView.directionalLockEnabled = YES;
	_contentScrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
	self.nextPageViewController = [[PCMagazineViewControllersFactory factory] viewControllerForPage:_initialPage];
    [self configureContentScrollForPage:_nextPageViewController.page];
	_contentScrollView.delegate = self;
	_contentScrollView.bounces = NO;
	[self.view addSubview:_contentScrollView];

	[self initTopMenu];
    

    UITapGestureRecognizer *tapGestureRecognizer = [[[UITapGestureRecognizer alloc]
                                                     initWithTarget:self action:@selector(tapGesture:)] autorelease];
    tapGestureRecognizer.delegate = self;
    tapGestureRecognizer.numberOfTapsRequired = 1;
    tapGestureRecognizer.numberOfTouchesRequired = 1;
    [self.view addGestureRecognizer:tapGestureRecognizer];

    [self createHud];
}

- (void)viewDidUnload
{	
    [super viewDidUnload];
	self.contentScrollView = nil;
    
    if (_shareView != nil) {
        [_shareView release];
        _shareView = nil;
    }
    
    if (_facebookViewController != nil) {
        [_facebookViewController release];
        _facebookViewController = nil;
    }
    
    if (_twitterController != nil) {
        [_twitterController release];
        _twitterController = nil;
    }
    
    if (_emailController != nil) {
        [_emailController release];
        _emailController = nil;
    }
    
    if (_emailToMagazineController != nil) {
        [_emailToMagazineController release];
        _emailToMagazineController = nil;
    }
    
    if (_subscriptionsMenuController != nil) {
        [_subscriptionsMenuController release];
        _subscriptionsMenuController = nil;
    }
    
    if (_popoverController != nil) {
        [_popoverController release];
        _popoverController = nil;
    }
}


-(NSUInteger)supportedInterfaceOrientations {
    return self.revision.orientationMask;
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return [self.revision supportsInterfaceOrientation:interfaceOrientation];
}


-(void)configureContentScrollForPage:(PCPage*)page
{
	//Contentsize configuration
	//After every page changing we need to recalculate content size of the revision scroll view depending on links of current page. Content size must allow scrolling to neighbour pages, and at the same time block scroll in direction where page links are empty (nil).
	
	if (!page) return;
	if (page.isComplete) [[ImageCache sharedImageCache] loadPrimaryImagesForPage:page]; 
	CGFloat pageWidth = self.view.bounds.size.width;
	CGFloat pageHeight = self.view.bounds.size.height;
	int widthMultiplier = 1;
	if (page.leftPage) widthMultiplier++;
	if (page.rightPage) {
        if (!_previewMode) {
            widthMultiplier++;
        } else {
            if (_horizontalPageIndex < _revision.issue.application.previewColumnsNumber) {
                widthMultiplier++;
            } else {
                UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:_revision.title
                                                                     message:[PCLocalizationManager localizedStringForKey:@"ALERT_MESSAGE_BUY_FULL_VERSION" value:@"Do you want to buy full version?"]
                                                                    delegate:self
                                                           cancelButtonTitle:[PCLocalizationManager localizedStringForKey:@"BUTTON_TITLE_NO" value:@"No"]
                                                           otherButtonTitles:[PCLocalizationManager localizedStringForKey:@"BUTTON_TITLE_YES" value:@"Yes"], nil]
                                          autorelease];
                [alertView show];
            }
        }
    }
	int heightMultiplier = 1;
	if (page.topPage) heightMultiplier++;
	if (page.bottomPage) heightMultiplier++;
	//To prevent calling delegate methods after changing content size delegate set to nil
	_contentScrollView.delegate = nil;
	_contentScrollView.contentSize = CGSizeMake(pageWidth*widthMultiplier, pageHeight*heightMultiplier);
	_contentScrollView.delegate = self;
	
	//configure offset
	//We need to determin the position of current page after changing content size
	CGFloat dx = page.leftPage?pageWidth:0;
	CGFloat dy = page.topPage?pageHeight:0;
	//_contentScrollView.contentOffset = CGPointMake(dx, dy);
	CGRect scrollBounds = _contentScrollView.bounds;
	scrollBounds.origin = CGPointMake(dx, dy);
	_contentScrollView.bounds = scrollBounds;
	
	if (self.currentPageViewController.page != page)
	{
		[_currentPageViewController.view removeFromSuperview];
		self.currentPageViewController = _nextPageViewController;
		CGRect frame = self.currentPageViewController.view.frame;
		frame.size = CGSizeMake(pageWidth, pageHeight);
		frame.origin = CGPointMake(dx, dy);	
		self.currentPageViewController.view.frame = frame;
		if (!self.currentPageViewController.view.superview)
		{
			_currentPageViewController.delegate = self;
			[_currentPageViewController loadFullView];
			[_contentScrollView addSubview:self.currentPageViewController.view];
		}
		
		self.nextPageViewController = nil;
		
	}
}

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
	if (scrollView.decelerating && !scrollView.dragging) return;
	
	CGFloat pageWidth = self.view.bounds.size.width;
	CGFloat pageHeight = self.view.bounds.size.height;
	CGFloat dx = _currentPageViewController.page.leftPage ? pageWidth : 0;
	CGFloat dy = _currentPageViewController.page.topPage ? pageHeight : 0;
	CGRect nextPageViewFrame = self.currentPageViewController.view.frame;
	PCPage* nextPage = nil;
	//This if determin the direction of scroll (horizontal or vertical)
	if ((!_currentPageViewController.page.topPage && !_currentPageViewController.page.bottomPage) || abs(dx-scrollView.contentOffset.x)>abs(dy-scrollView.contentOffset.y))
	{
		//This code prevent any diagonal scrolling
		CGRect scrollBounds = scrollView.bounds;
		scrollBounds.origin = CGPointMake(scrollView.contentOffset.x, dy);
		_contentScrollView.bounds = scrollBounds;
		
		//here we determin the direction of horizontal scroll (right or left)
		if (scrollView.contentOffset.x > dx ) {
			nextPage = _currentPageViewController.page.rightPage;
			nextPageViewFrame.origin = CGPointMake(dx + pageWidth, dy);
		}
		else {
			nextPage = _currentPageViewController.page.leftPage;
			nextPageViewFrame.origin = CGPointMake(dx - pageWidth, dy);
		}
	}
	else
	{
		//This code prevent any diagonal scrolling
		CGRect scrollBounds = scrollView.bounds;
		scrollBounds.origin = CGPointMake(dx, scrollView.contentOffset.y);
		_contentScrollView.bounds = scrollBounds;
		
		//Here we determin the direction of vertical scrll (top or bottom)
		if (scrollView.contentOffset.y > dy ) {
			nextPage = _currentPageViewController.page.bottomPage;
			nextPageViewFrame.origin = CGPointMake(dx, dy + pageHeight);
		}
		else {
			nextPage = _currentPageViewController.page.topPage;
			nextPageViewFrame.origin = CGPointMake(dx, dy - pageHeight);
		}
	}
	
	
	if (!nextPage) return;

//	if (nextPage.isComplete) [[ImageCache sharedImageCache] loadPrimaryImagesForPage:nextPage]; 
//	NSLog(@"NEXT PAGE - %d", nextPage.identifier);

	if (_nextPageViewController.page != nextPage)
	{
        if (nextPage == _currentPageViewController.page.rightPage) {
            ++_horizontalPageIndex;
        } else if (nextPage == _currentPageViewController.page.leftPage) {
            --_horizontalPageIndex;
        }
		[_nextPageViewController.view removeFromSuperview], self.nextPageViewController = nil;
		self.nextPageViewController = [[PCMagazineViewControllersFactory factory] viewControllerForPage:nextPage];
		self.nextPageViewController.view.frame = nextPageViewFrame;
		_nextPageViewController.delegate = self;
		[_nextPageViewController loadFullView];
		[_contentScrollView addSubview:self.nextPageViewController.view];
	}
}

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
//	if (_nextPageViewController.page.isComplete) [[ImageCache sharedImageCache] loadPrimaryImagesForPage:_nextPageViewController.page]; 
	BOOL isVerticalOffset = scrollView.contentOffset.x == CGRectGetMinX(_nextPageViewController.view.frame);
	BOOL isHorizontalOffset = scrollView.contentOffset.y == CGRectGetMinY(_nextPageViewController.view.frame);
	
	//If page changing has occurred we need to reconfigure scroll view with new page
	if (isVerticalOffset && isHorizontalOffset)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:PCBoostPageNotification object:_nextPageViewController.page userInfo:nil];
		[self configureContentScrollForPage:_nextPageViewController.page];
        //[self dismissVideo];
	}
}

-(void) deviceOrientationDidChange:(NSNotification*)notif
{
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	if (!UIDeviceOrientationIsValidInterfaceOrientation(orientation)) return;
    
    PCPageElementBody* bodyElement;
	// TODO: to refactor
    [_hudController update];

	if (_currentPageViewController.page.onRotatePage) {
		[self gotoPage:_currentPageViewController.page.onRotatePage];

	}
    else if (_contentScrollView.dragging || _contentScrollView.decelerating){
    }
    else if ((bodyElement = (PCPageElementBody*)[_currentPageViewController.page firstElementForType:PCPageElementTypeBody]
) && bodyElement.showGalleryOnRotate){
        if (UIDeviceOrientationIsLandscape(orientation) && !UIDeviceOrientationIsLandscape(_currentInterfaceOrientation)) {
            [self showGallery];
            NSLog(@"show galery");
            [UIViewController attemptRotationToDeviceOrientation];
        } else if (!UIDeviceOrientationIsLandscape(orientation) && UIDeviceOrientationIsLandscape(_currentInterfaceOrientation)){
            [self galleryViewControllerWillDismiss:nil];
            NSLog(@"hide galery");
            [UIViewController attemptRotationToDeviceOrientation];
        } else{
            NSLog(@"nothing");

        }
    }
	_currentInterfaceOrientation = (UIInterfaceOrientation)orientation;
}

#pragma mark - GalleryViewControllerDelegate

- (void)galleryViewControllerWillDismiss:(GalleryViewController *)galleryViewController
{
    if ([self.delegate respondsToSelector:@selector(revisionViewController:willDismissGalleryViewController:)]) {
        [self.delegate revisionViewController:self willDismissGalleryViewController:galleryViewController];
		_contentScrollView.bounds = bufferBound;
    }
	//[self.navigationController popToViewController:self animated:NO];
}

#pragma mark PCActionDelegate methods

-(void)showGallery
{
	/*if (!_contentScrollView.dragging && !_contentScrollView.decelerating)
	{
		GalleryViewController* galleryViewController = [[[GalleryViewController alloc] initWithPage:_currentPageViewController.page] autorelease];
        galleryViewController.delegate = self;
		[self.navigationController pushViewController:galleryViewController  animated:NO];
	}*/
	bufferBound = _contentScrollView.bounds;
	if (!_contentScrollView.dragging && !_contentScrollView.decelerating)
	{
		if ([self.delegate respondsToSelector:@selector(revisionViewController:willPresentGalleryViewController:)]) {
			GalleryViewController* galleryViewController = [[[GalleryViewController alloc] initWithPage:_currentPageViewController.page] autorelease];
			galleryViewController.delegate = self;
			[self.delegate revisionViewController:self
				 willPresentGalleryViewController:galleryViewController];
		}

	}
        
}

- (void)showCrossword:(NSInteger)crosswordID
{
    
}

-(void)gotoPage:(PCPage *)page
{
	self.nextPageViewController = [[PCMagazineViewControllersFactory factory] viewControllerForPage:page];
	if (!_nextPageViewController.page.isComplete)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:PCBoostPageNotification object:_nextPageViewController.page userInfo:nil];
	}
	[self configureContentScrollForPage:_nextPageViewController.page];
    
    switch (_revision.orientationMask) {
        case (UIInterfaceOrientationMaskPortrait | UIInterfaceOrientationMaskPortraitUpsideDown):
            if (!UIInterfaceOrientationIsPortrait(_currentInterfaceOrientation)) {
                _currentInterfaceOrientation = UIInterfaceOrientationPortrait;
            }
            break;
        case (UIInterfaceOrientationMaskLandscape):
            if (!UIInterfaceOrientationIsLandscape(_currentInterfaceOrientation)) {
                _currentInterfaceOrientation = UIInterfaceOrientationLandscapeLeft;
            }
            break;
        default:
            break;
    }
    //[self dismissVideo];
}

- (void)showVideo:(UIView *)videoView
{
    [self.view addSubview:videoView];
    [self.view bringSubviewToFront:videoView];
}

- (void)showTopBar
{
    
	
    if (UIInterfaceOrientationIsPortrait([UIApplication sharedApplication].statusBarOrientation)) {
        topMenuView.hidden = NO;
        topMenuView.alpha = 0.75f;
        [self.view bringSubviewToFront:topMenuView];
    } 
}

- (void)hideTopBar
{
    topMenuView.hidden = YES;
    topMenuView.alpha = 0;
    [self.view sendSubviewToBack:topMenuView];
    
   }


- (void)initTopMenu
{
    topMenuView.hidden = YES;
    topMenuView.alpha = 0;
    [topMenuView setFrame:CGRectMake(0, 0, self.view.frame.size.width, 43)];
	
    int lastTocSummaryIndex = -1;
    if ([_revision.toc count] > 0)
    {
        for (int i = [_revision.toc count]-1; i >= 0; i--)
		{
			PCTocItem *tempTocItem = [_revision.toc objectAtIndex:i];
			if (tempTocItem.thumbSummary)
			{
				lastTocSummaryIndex = i;
				break;
			}
		}
    }
    
    [self.view addSubview:topMenuView];
    
  }

- (void) adjustHelpButton
{
    BOOL        hide = NO;
    
    if (_revision.helpPages)
    {
		if([[_revision.helpPages objectForKey:@"horizontal"] isEqualToString:@""] && [[_revision.helpPages objectForKey:@"vertical"] isEqualToString:@""])
		{
			hide = YES;
		}
    }
}

- (void)tapGesture:(UIGestureRecognizer *)recognizer
{
    [_hudController tap];
}

#pragma mark - UIGestureRecognizerDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if ([touch.view isKindOfClass:UIButton.class] ||
        touch.view.tag == CELL_CONTENT_TAG) {
        return NO;
    }
    
    return YES;
}
#pragma mark - RRHudControllerDelegate

- (void)hudControllerDismissAllPopups:(PCHudController *)hudController
{
    if (_shareView != nil && _shareView.presented) {
        [_shareView dismiss];
    }
}

- (void)hudController:(PCHudController *)hudController selectedTocItem:(PCTocItem *)tocItem
{
    NSArray *revisionPages = _revision.pages;
    for (PCPage *page in revisionPages) {
        if (page.identifier == tocItem.firstPageIdentifier) {
            [self gotoPage:page];
            break;
        }
    }
}

- (void)hudController:(PCHudController *)hudController topBarView:(PCTopBarView *)topBarView
         buttonTapped:(UIButton *)button
{
    if (button == topBarView.backButton) {
        [self dismiss];
    } else if (button == topBarView.contactButton) {
        [self sendMailToMagazine];
    } else if (button == topBarView.summaryButton) {
        // nothing
    } else if (button == topBarView.subscriptionsButton) {
        if (!_subscriptionsMenuController)
            _subscriptionsMenuController = [[PCSubscriptionMenuViewController alloc] initWithSubscriptionFlag:[self.revision.issue.application hasIssuesProductID]];
        if (!_popoverController)
            _popoverController = [[UIPopoverController alloc] initWithContentViewController:_subscriptionsMenuController];
        [_popoverController presentPopoverFromRect:button.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
    } else if (button == topBarView.shareButton) {
        if (_shareView == nil) {
            _shareView = [[PCShareView configuredShareView] retain];
            _shareView.delegate = self;
        }
        
        if (_shareView.presented) {
            [_shareView dismiss];
        } else {
            [_shareView presentInView:self.view atPoint:button.center];
        }
    }
}

- (void)hudController:(PCHudController *)hudController topBarView:(PCTopBarView *)topBarView searchText:(NSString *)searchText
{
	NSBundle *bundle = [NSBundle bundleWithURL:[[NSBundle mainBundle] URLForResource:@"PadCMS-CocoaTouch-Core-Resources" withExtension:@"bundle"]];
	PCSearchViewController* searchViewController = [[PCSearchViewController alloc] initWithNibName:@"PCSearchViewController" bundle:bundle];
	searchViewController.searchKeyphrase = searchText;
	searchViewController.revision = _revision;
	searchViewController.delegate = self;
	[self.navigationController pushViewController:searchViewController animated:NO];
	
	[searchViewController release];
}

#pragma mark - delegate methods
- (void)dismiss
{
    if ([self.delegate respondsToSelector:@selector(revisionViewControllerDidDismiss:)]) {
        [self.delegate revisionViewControllerDidDismiss:self];
        [[PCVideoManager sharedVideoManager] setIsStartVideoShown:NO];
    }
}

#pragma mark - PCSearchViewControllerDelegate

- (void) showRevisionWithIdentifier:(NSInteger) revisionIdentifier andPageIndex:(NSInteger) pageIndex
{
	[self dismissPCSearchViewController:nil];
	NSAssert(pageIndex >= 0 && pageIndex < [_revision.pages count], @"pageIndex not within range");
	[self gotoPage:[_revision.pages objectAtIndex:pageIndex]];
	
}

-(void)dismissPCSearchViewController:(PCSearchViewController *)currentPCSearchViewController
{
	[self.navigationController popViewControllerAnimated:NO];
	
	UIViewController *viewController = [[UIViewController alloc] init];
	[self presentModalViewController:viewController animated:NO];
	[self dismissModalViewControllerAnimated:NO];
	[viewController release];
}

#pragma mark - ContacterDelegate

- (void)sendMailToMagazine{
    if (_emailToMagazineController == nil) {
        
        NSDictionary *emailMessage = [[PCConfig padCMSConfig] valueForKeyPath:@"PCTopBarViewStyle.PCTopBarViewContactButtonStyle.MailMessage"];
        _emailToMagazineController = [[PCEmailController alloc] initWithMessage:emailMessage];
        _emailToMagazineController.delegate = self;
    }
    
    [_emailToMagazineController emailShow];

}


#pragma mark - PCShareViewDelegate

- (void)shareViewFacebookShare:(PCShareView *)shareView
{
    if (_facebookViewController == nil) {
        NSString *facebookMessage = [[_revision.issue.application.notifications objectForKey:PCFacebookNotificationType]objectForKey:PCApplicationNotificationMessageKey];
        _facebookViewController = [[PCFacebookViewController alloc] initWithMessage:facebookMessage];
    }
    
    [_facebookViewController initFacebookSharer];
}

- (void)shareViewTwitterShare:(PCShareView *)shareView
{
    if (_twitterController == nil) {
        NSString *twitterMessage = [[self.revision.issue.application.notifications objectForKey:PCTwitterNotificationType]objectForKey:PCApplicationNotificationMessageKey];
        _twitterController = [[PCTwitterNewController alloc] initWithMessage:twitterMessage];
        _twitterController.delegate = self;
    }
    
    [_twitterController showTwitterController];
}

- (void)shareViewEmailShare:(PCShareView *)shareView
{
    if (_emailController == nil) {
        NSDictionary *emailMessage = [self.revision.issue.application.notifications objectForKey:PCEmailNotificationType];
        _emailController = [[PCEmailController alloc] initWithMessage:emailMessage];
        _emailController.delegate = self;
    }
    
    [_emailController emailShow];
}

#pragma mark - PCTwitterNewControllerDelegate

- (void)dismissPCNewTwitterController:(TWTweetComposeViewController *)currentPCTwitterNewController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showPCNewTwitterController:(TWTweetComposeViewController *)tweetController
{
    [self presentViewController:tweetController animated:YES completion:nil];
}

#pragma mark - PCEmailControllerDelegate

- (void)dismissPCEmailController:(MFMailComposeViewController *)currentPCEmailController
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)showPCEmailController:(MFMailComposeViewController *)emailControllerToShow
{
    [self presentViewController:emailControllerToShow animated:YES completion:nil];
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if ([buttonTitle isEqualToString:[PCLocalizationManager localizedStringForKey:@"BUTTON_TITLE_YES"
                                                                            value:@"Yes"]]) {
        if ([[InAppPurchases sharedInstance] canMakePurchases]) {
            [[InAppPurchases sharedInstance] purchaseForProductId:_revision.issue.productIdentifier];
        } else {
			UIAlertView *alert = [[[UIAlertView alloc] initWithTitle:[PCLocalizationManager localizedStringForKey:@"ALERT_TITLE_CANT_MAKE_PURCHASE"
                                                                                                           value:@"You can't make the purchase"]
                                                            message:nil
                                                           delegate:nil
                                                  cancelButtonTitle:[PCLocalizationManager localizedStringForKey:@"BUTTON_TITLE_OK"
                                                                                                           value:@"OK"]
                                                  otherButtonTitles:nil] autorelease];
			[alert show];
        }
    }
}

#pragma mark - PCSubscriptionMenuViewControllerDelegate methods

- (void)subscriptionsMenuButtonWillPressed
{
    [_popoverController dismissPopoverAnimated:NO];
}

@end