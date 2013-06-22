//
//  SESpringBoard.m
//  SESpringBoardDemo
//
//  Created by Sarp Erdag on 11/5/11.
//  Copyright (c) 2011 Sarp Erdag. All rights reserved.
//

#import "SESpringBoard.h"
#import "UIViewController+SEViewController.h"

@implementation SESpringBoard

#define ITEMS_PER_PAGE_IPHONE_5             15
#define ITEMS_PER_PAGE_IPHONE_4S_AND_LESS   12
#define IPHONE_STANDARD_SCREEN_HEIGHT  480


#define ITEMS_PER_PAGE(x) (x == IPHONE_STANDARD_SCREEN_HEIGHT) ? ITEMS_PER_PAGE_IPHONE_4S_AND_LESS : ITEMS_PER_PAGE_IPHONE_5
#define NUMBER_OF_COLUMNS 3

@synthesize items, title, launcher, isInEditingMode, itemCounts;

- (IBAction) doneEditingButtonClicked {
    [self disableEditingMode];
}

- (id) initWithTitle:(NSString *)boardTitle items:(NSMutableArray *)menuItems image:(UIImage *) image
{
    self = [super initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
    [self setUserInteractionEnabled:YES];
    if (self)
    {
        self.launcher = image;
        self.isInEditingMode = NO;
        
        // create the top bar
        navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 44)];
        
        // add title for the navigation bar
        UINavigationItem *navigationItem = [[UINavigationItem alloc] initWithTitle:boardTitle];
        navigationBar.items = @[navigationItem];
        
        // add a button to the right side that will become visible when the items are in editing mode
        // clicking this button ends editing mode for all items on the springboard
        doneEditingButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        doneEditingButton.frame = CGRectMake(265, 5, 50, 34.0);
        [doneEditingButton setTitle:@"Done" forState:UIControlStateNormal];
        doneEditingButton.backgroundColor = [UIColor clearColor];
        [doneEditingButton addTarget:self action:@selector(doneEditingButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [doneEditingButton setHidden:YES];
        [navigationBar addSubview:doneEditingButton];
        
        [self addSubview:navigationBar];
        
        // create a container view to put the menu items inside
        itemsContainer = [[UIScrollView alloc] initWithFrame:CGRectMake(10, navigationBar.frame.size.height+5, self.frame.size.width-20, self.frame.size.height-navigationBar.frame.size.height-30)];
        itemsContainer.delegate = self;
        [itemsContainer setScrollEnabled:YES];
        [itemsContainer setPagingEnabled:YES];
        itemsContainer.showsHorizontalScrollIndicator = NO;
        [self addSubview:itemsContainer];
        
        self.items = menuItems;
        int itemsPerPage = ITEMS_PER_PAGE([UIScreen mainScreen].bounds.size.height);
        int counter = 0;
        int horgap = 0;
        int vergap = 0;
        int numberOfPages = (ceil((float)[menuItems count] / itemsPerPage));
        int currentPage = 0;
        for (SEMenuItem *item in self.items) {
            currentPage = counter / itemsPerPage;
            item.tag = counter;
            item.delegate = self;
            [item setFrame:CGRectMake(item.frame.origin.x + horgap + (currentPage*itemsContainer.frame.size.width), item.frame.origin.y + vergap, item.frame.size.width, item.frame.size.height)];
            [itemsContainer addSubview:item];
            horgap = horgap + item.frame.size.width;
            counter = counter + 1;
            if(counter % NUMBER_OF_COLUMNS == 0){
                vergap = vergap + item.frame.size.height-5;
                horgap = 0;
            }
            if (counter % itemsPerPage == 0) {
                vergap = 0;
            }
        }
        
        // record the item counts for each page
        self.itemCounts = [NSMutableArray array];
        int totalNumberOfItems = [self.items count];
        int numberOfFullPages = totalNumberOfItems % itemsPerPage;
        int lastPageItemCount = totalNumberOfItems - numberOfFullPages%itemsPerPage;
        for (int i=0; i<numberOfFullPages; i++)
            [self.itemCounts addObject:@(itemsPerPage)];
        if (lastPageItemCount != 0)
            [self.itemCounts addObject:@(lastPageItemCount)];
        
        [itemsContainer setContentSize:CGSizeMake(numberOfPages*itemsContainer.frame.size.width, itemsContainer.frame.size.height)];
        
        // add a page control representing the page the scrollview controls
        pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.frame.size.height-navigationBar.frame.size.height-5, self.frame.size.width, 20)];
        if (numberOfPages > 1) {
            pageControl.numberOfPages = numberOfPages;
            pageControl.currentPage = 0;
            [self addSubview:pageControl];
        }
        // add listener to detect close view events
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeViewEventHandler:) name:@"closeView" object:nil];
    }
    return self;
}

+ (id) initWithTitle:(NSString *)boardTitle items:(NSMutableArray *)menuItems launcherImage:(UIImage *)image
{
    SESpringBoard *tmpInstance = [[SESpringBoard alloc] initWithTitle:boardTitle items:menuItems image:image];
	return tmpInstance;
};


// transition animation function required for the springboard look & feel
- (CGAffineTransform)offscreenQuadrantTransformForView:(UIView *)theView {
    CGPoint parentMidpoint = CGPointMake(CGRectGetMidX(theView.superview.bounds), CGRectGetMidY(theView.superview.bounds));
    CGFloat xSign = (theView.center.x < parentMidpoint.x) ? -1.f : 1.f;
    CGFloat ySign = (theView.center.y < parentMidpoint.y) ? -1.f : 1.f;
    return CGAffineTransformMakeTranslation(xSign * parentMidpoint.x, ySign * parentMidpoint.y);
}

#pragma mark - MenuItem Delegate Methods

- (void)launch:(int)index withVCToLoad:(UIViewController *)viewController
{
    
    // if the springboard is in editing mode, do not launch any view controller
    if (isInEditingMode)
        return;
    
    // first disable the editing mode so that items will stop wiggling when an item is launched
    [self disableEditingMode];
    
    // create a navigation bar
    nav = [UINavigationController alloc];
    
    // manually trigger the appear method
    [viewController viewDidAppear:YES];
    
    
    [viewController setupCloseButtonWithImage:launcher];
    
    [nav initWithRootViewController:viewController];
    [nav viewDidAppear:YES];
    
    nav.view.alpha = 0.f;
    nav.view.transform = CGAffineTransformMakeScale(.1f, .1f);
    [self addSubview:nav.view];
    
    [UIView animateWithDuration:.3f  animations:^{
        // fade out the buttons
        for(SEMenuItem *item in self.items) {
            item.transform = [self offscreenQuadrantTransformForView:item];
            item.alpha = 0.f;
        }
        
        // fade in the selected view
        nav.view.alpha = 1.f;
        nav.view.transform = CGAffineTransformIdentity;
        [nav.view setFrame:CGRectMake(0,0, self.frame.size.width, self.frame.size.height-20)];
        
        // fade out the top bar
        [navigationBar setFrame:CGRectMake(0, -44, self.frame.size.width, 44)];
    }];
}

- (void)removeFromSpringboard:(int)index {
    
    // Remove the selected menu item from the springboard, it will have a animation while disappearing
    SEMenuItem *menuItem = items[index];
    
    int numberOfItemsInCurrentPage = [(self.itemCounts)[pageControl.currentPage] intValue];
    
    // First find the index of the current item with respect of the current page
    // so that only the items coming after the current item will be repositioned.
    // The index of the item can be found by looking at its coordinates
    int mult = ((int)menuItem.frame.origin.y) / menuItem.frame.size.height-5;
    int add = ((int)menuItem.frame.origin.x % (int)itemsContainer.frame.size.width)/menuItem.frame.size.width;
    int pageSpecificIndex = (mult*NUMBER_OF_COLUMNS) + add;
    [menuItem removeFromSuperview];
    int remainingNumberOfItemsInPage = numberOfItemsInCurrentPage-pageSpecificIndex;
    
    // Select the items listed after the deleted menu item
    // and move each of the ones on the current page, one step back.
    // The first item of each row becomes the last item of the previous row.
    for (int i = index+1; i<[items count]; i++) {
        SEMenuItem *item = items[i];
        [UIView animateWithDuration:0.2 animations:^{
            
            // Only reposition the items in the current page, coming after the current item
            if (i < index + remainingNumberOfItemsInPage) {
                
                int intVal = item.frame.origin.x;
                // Check if it is the first item in the row
                if (intVal %NUMBER_OF_COLUMNS== 0)
                    [item setFrame:CGRectMake(item.frame.origin.x+2*item.frame.size.width, item.frame.origin.y-item.frame.size.height-5, item.frame.size.width, item.frame.size.height)];
                else
                    [item setFrame:CGRectMake(item.frame.origin.x-item.frame.size.width, item.frame.origin.y, item.frame.size.width, item.frame.size.height)];
            }
            
            // Update the tag to match with the index. Since the an item is being removed from the array,
            // all the items' tags coming after the current item has to be decreased by 1.
            [item updateTag:item.tag-1];
        }];
    }
    // remove the item from the array of items
    [items removeObjectAtIndex:index];
    // also decrease the record of the count of items on the current page and save it in the array holding the data
    numberOfItemsInCurrentPage--;
    (self.itemCounts)[pageControl.currentPage] = @(numberOfItemsInCurrentPage);
}

- (void)closeViewEventHandler: (NSNotification *) notification {
    UIView *viewToRemove = (UIView *) notification.object;
    [UIView animateWithDuration:.3f animations:^{
        viewToRemove.alpha = 0.f;
        viewToRemove.transform = CGAffineTransformMakeScale(.1f, .1f);
        for(SEMenuItem *item in self.items) {
            item.transform = CGAffineTransformIdentity;
            item.alpha = 1.f;
        }
        [navigationBar setFrame:CGRectMake(0, 0, self.frame.size.width, 44)];
    } completion:^(BOOL finished) {
        [viewToRemove removeFromSuperview];
    }];
    
    // release the dynamically created navigation bar
}

#pragma mark - UIScrollView Delegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)sender {
    CGFloat pageWidth = itemsContainer.frame.size.width;
    int page = floor((itemsContainer.contentOffset.x - pageWidth / 2) / pageWidth) + 1;
    pageControl.currentPage = page;
}

#pragma mark - Custom Methods

- (void) disableEditingMode {
    // loop thu all the items of the board and disable each's editing mode
    for (SEMenuItem *item in items)
        [item disableEditing];
    
    [doneEditingButton setHidden:YES];
    self.isInEditingMode = NO;
}

- (void) enableEditingMode {
    
    for (SEMenuItem *item in items)
        [item enableEditing];
    
    // show the done editing button
    [doneEditingButton setHidden:NO];
    self.isInEditingMode = YES;
}

@end
