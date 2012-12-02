//
//  HelloWorldLayer.m
//  Apes
//
//  Created by 余 向洋 on 12-11-23.
//  Copyright __MyCompanyName__ 2012年. All rights reserved.
//


#import "GameScene.h"
#import "MainMenuScene.h"
#import "Enemy.h"

@implementation GameScene
-(id) init
{
    if (self = [super init])
    {
        _bgLayer = [[BackgroundLayer alloc] init];
        _objLayer = [[ObjectsLayer alloc] init];
        _hudLayer = [[HudLayer alloc] initWithObjLayer:_objLayer];
        [self addChild:_bgLayer z:-1];
        [self addChild:_objLayer];
        [self addChild:_hudLayer];
    }
    return self;
}
@end

@implementation BackgroundLayer

// on "init" you need to initialize your instance
-(id) init
{
	if (self=[super init]) {
        static ccTime BACKGROUND_SCROLL_DURATION = 3.0;
		CCSprite *city1 = [CCSprite spriteWithFile:@"city.jpg"];
        city1.anchorPoint = ccp(0,0);
        city1.position = ccp(0,0);
        CCSprite *city2 = [CCSprite spriteWithFile:@"city.jpg"];
        city2.anchorPoint = ccp(0,0);
        city2.position = ccp(city1.contentSize.width - 3, 0);
        _city = [[CCSprite alloc] init];
        [_city addChild:city1];
        [_city addChild:city2];
        id a1 = [CCMoveBy actionWithDuration:BACKGROUND_SCROLL_DURATION position:ccp(-city1.contentSize.width, 0)];
        id a2 = [CCPlace actionWithPosition:ccp(0, 0)];
        [_city runAction:[CCRepeatForever actionWithAction:[CCSequence actions:a1, a2, nil]]];
        
        CCSprite *ground1 = [CCSprite spriteWithFile:@"ground.jpg"];
        ground1.anchorPoint = ccp(0,0);
        ground1.position = ccp(0,0);
        CCSprite *ground2 = [CCSprite spriteWithFile:@"ground.jpg"];
        ground2.anchorPoint = ccp(0,0);
        ground2.position = ccp(ground1.contentSize.width - 3, 0);
        _ground = [[CCSprite alloc] init];
        [_ground addChild:ground1];
        [_ground addChild:ground2];
        a1 = [CCMoveBy actionWithDuration:BACKGROUND_SCROLL_DURATION position:ccp(-ground1.contentSize.width, 0)];
        a2 = [CCPlace actionWithPosition:ccp(0, 0)];
        [_ground runAction:[CCRepeatForever actionWithAction:[CCSequence actions:a1, a2, nil]]];
        [self addChild:_city];
        [self addChild:_ground];
	}
	return self;
}

// on "dealloc" you need to release all your retained objects
- (void) dealloc
{
	[super dealloc];
}
@end

@implementation ObjectsLayer
{
    BOOL _isJumping;
//    NSMutableArray *_bananasPool;
    NSMutableArray *_bananas;
    NSMutableArray *_enemies;
}

#define kNumBananas 5

- (id)init
{
    if (self = [super init])
    {
        _isJumping = NO;
        [[CCSpriteFrameCache sharedSpriteFrameCache] addSpriteFramesWithFile:@"orang.plist"];
        CCSpriteBatchNode *spritesheet = [CCSpriteBatchNode batchNodeWithFile:@"orang.png"];
        [self addChild:spritesheet];
        
        _player = [CCSprite spriteWithSpriteFrameName:@"orang1.png"];
        _player.position = ccp(120, 90);
        NSMutableArray *playerFrames = [[NSMutableArray alloc] init];
        [playerFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"orang1.png"]];
        [playerFrames addObject:[[CCSpriteFrameCache sharedSpriteFrameCache] spriteFrameByName:@"orang2.png"]];
        CCAnimation *playerAnimation = [CCAnimation animationWithFrames:playerFrames delay:0.15f];
        [_player runAction:[CCRepeatForever actionWithAction:[CCAnimate actionWithAnimation:playerAnimation restoreOriginalFrame:NO]]];
        [spritesheet addChild:_player];
        
//        _bananasPool = [[NSMutableArray alloc] init];
//        for (int i = 0; i < kNumBananas; i++) {
//            CCSprite *banana = [CCSprite spriteWithFile:@"banana.png"];
//            banana.visible = NO;
//            [_bananasPool addObject:banana];
//            [self addChild:banana];
//        }
        
        _enemies = [[NSMutableArray alloc] init];
        _bananas = [[NSMutableArray alloc] init];
        
        [self schedule:@selector(addEnemy) interval:0.5f];
        [self scheduleUpdate];
    }
    return self;
}

#define ARC4RANDOM_MAX      0x100000000
- (void)addEnemy
{
    CGSize winSize = [[CCDirector sharedDirector] winSize];
    double p0 = ((double)arc4random() / ARC4RANDOM_MAX);
    if (p0 < 0.4) {
        double p1 = ((double)arc4random() / ARC4RANDOM_MAX);
        CCSprite *enemy = nil;
        if (p1 < 0.5) {     // police
            enemy = [Police police];
        } else {    // car
            enemy = [Car car];
        }
        enemy.position = ccp(winSize.width, 80);
        [enemy runAction:[CCMoveBy actionWithDuration:3.0 position:ccp(-winSize.width - enemy.contentSize.width, 0)]];
        [self addChild:enemy];
        [_enemies addObject:enemy];
    }
}

- (void)update:(ccTime)dt
{
    CCSprite *policeToDelete = nil;
    CCSprite *bananaToDelete = nil;
    for (CCSprite *enemy in _enemies) {
        if (CGRectIntersectsRect(enemy.boundingBox, _player.boundingBox)) {
            [[CCDirector sharedDirector] replaceScene:[[MainMenuScene alloc] init]];
        }

        for (CCSprite *banana in _bananas) {
            if (CGRectIntersectsRect(enemy.boundingBox, banana.boundingBox)) {
                policeToDelete = enemy;
                bananaToDelete = banana;
                break;
            }
        }
        
        if (policeToDelete) {
            break;
        }
    }
    
    if (policeToDelete) {        
        [_enemies removeObject:policeToDelete];
        [_bananas removeObject:bananaToDelete];
        [self removeChild:bananaToDelete cleanup:YES];
        [self removeChild:policeToDelete cleanup:YES];
    }
}

- (void)onJumpTapped
{
    if (!_isJumping) {
        _isJumping = YES;
        id action1 = [CCMoveBy actionWithDuration:0.35 position:ccp(0,120)];
        id action2 = [action1 reverse];
        id action3 = [CCCallBlock actionWithBlock:^{_isJumping = NO;}];
        [_player runAction:[CCSequence actions:[CCEaseOut actionWithAction:action1 rate:2], [CCEaseIn actionWithAction:action2 rate:2], action3, nil]];
    }
}

- (void)onShootTapped
{
//    if (_bananasPool.count > 0) {
//        CGSize winSize = [CCDirector sharedDirector].winSize;
//        CCSprite *banana = _bananasPool[0];
//        [_bananasPool removeObjectAtIndex:0];
//        
//        [_flyingBananas addObject:banana];
//        banana.position = ccpAdd(_player.position, ccp(_player.contentSize.width/2, 0));
//        banana.visible = YES;
//        [banana stopAllActions];
//        [banana runAction:[CCSequence actions:
//                           [CCMoveBy actionWithDuration:0.5 position:ccp(winSize.width, 0)],
//                           [CCCallBlockN actionWithBlock:^(CCNode *banana) {
//            banana.visible = NO;
//            [_bananasPool addObject:banana];
//        }], nil]];
//    }
//
    
    CGSize winSize = [CCDirector sharedDirector].winSize;
    CCSprite *banana = [[CCSprite alloc] initWithFile:@"banana.png"];
    
    [_bananas addObject:banana];
    banana.position = ccpAdd(_player.position, ccp(_player.contentSize.width/2, 0));
    [banana stopAllActions];
    [banana runAction:[CCSequence actions:
                       [CCMoveBy actionWithDuration:0.5 position:ccp(winSize.width, 0)],
                       [CCCallBlockN actionWithBlock:^(CCNode *banana) {
        [_bananas removeObject:banana];
        [self removeChild:banana cleanup:YES];
    }], nil]];
    [self addChild:banana];
}

@end

@implementation HudLayer

-(id)initWithObjLayer:(ObjectsLayer*)objLayer
{
    if (self = [super init])
    {
        _objLayer = objLayer;
        _jumpButton = [CCMenuItemImage itemFromNormalImage:@"jump_button.png" selectedImage:@"jump_button.png" target:_objLayer selector:@selector(onJumpTapped)];
        _jumpButton.position = ccp(40, 50);
        _shootButton = [CCMenuItemImage itemFromNormalImage:@"shot_button.png" selectedImage:@"shot_button.png" target:_objLayer selector:@selector(onShootTapped)];
        _shootButton.position = ccp(440, 50);
        CCMenu *menu = [CCMenu menuWithItems:_jumpButton, _shootButton, nil];
        menu.position = CGPointZero;
        [self addChild:menu];
    }
    return self;
}

@end