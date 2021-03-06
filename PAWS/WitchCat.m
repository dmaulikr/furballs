//
//  WitchCat.m
//  PAWS
//
//  Created by Phisit Jorphochaudom on 11/3/11.
//  Copyright (c) 2011 University of Southern California. All rights reserved.
//

#import "WitchCat.h"

@implementation WitchCat

@synthesize fearAuraPower;

-(WitchCat*) initWithUnit: (Unit *) unit{
    self = [super init];
    if (self) {
        
        [self initWithClassName:unit.unitClassName andFlipX:unit.isFlipX];
        [self setUnitID: [unit unitID]];
        [self setHitPoint: [unit hitPoint]];
        [self setMaxHitPoint:[self hitPoint]];
        [self setAttack: [unit attack]];
        [self setAttackRange: [unit attackRange]];
        [self setAttackSpeed: [unit attackSpeed]];
        [self setSpeed: [unit speed]];
        [self setSpawnRate: [unit spawnRate]];
        [self setCoolDown: 0];
        [self setSkill: [unit skill]];
        [self setUnitName: [unit unitName]];
        [self setPosition:[unit position]];
        [self setFrameName: [NSString stringWithString:[unit frameName]]];
        [self setFearAuraPower:kFearAuraPower];
        [self setLevelSpeedFactor: [unit levelSpeedFactor]];
        self.stateTime = 0;
        [self setState: IDLE];
        [self setStatus:NORMAL];
    }
    return self;
}

-(void) updateStateWithDeltaTime:(ccTime)deltaTime 
             andListOfEnemyUnits:(NSMutableArray *)listOfEnemyUnits {
    if ([self hitPoint] <= 0) {
        // Remove fear effect
        for (Unit *enemyUnit in listOfEnemyUnits) {
            if ([enemyUnit status] == FEAR) {
                if (fearAuraPower != 0.0) {
                    enemyUnit.attack /= [self fearAuraPower];
                    [enemyUnit setStatus:NORMAL];
                }
                
            }
        }
        [self setState:DEAD];
        [self stopActionByTag:MOVEACTION];
        [self setFaceTexture:CRY];
        return;
    }
    
    if ([self updateOutOfBound]) {
        return;
    }
    
    // Collision detection
    [self updateHPLabel];
    CGRect playerRect = [self adjustedBoundingBox];
    
    BOOL isIntersect = FALSE;
    
    //Do something
    for (Unit *enemyUnit in listOfEnemyUnits) {
        
        // Apply aura for unit in kFearAuraRadius
        if (
            ccpDistance(self.position, enemyUnit.position) 
            <= kFearAuraRadius
            ) {
            if (
                [enemyUnit status] == NORMAL
                ) {
                enemyUnit.attack *= [self fearAuraPower];
                [enemyUnit setStatus:FEAR];
            }
        } else {
            if ([enemyUnit status] == FEAR) {
                if (fearAuraPower != 0.0) {
                    enemyUnit.attack /= [self fearAuraPower];
                    [enemyUnit setStatus:NORMAL];
                }
                
            }
        }
        
        CGRect enemyRect = [enemyUnit adjustedBoundingBox];
        [enemyUnit updateHPLabel];
        
        
        
        if (
            CGRectIntersectsRect(playerRect, enemyRect) 
            && self.zOrder == enemyUnit.zOrder
            && [enemyUnit state] != RUN
            && [enemyUnit status] != GHOST
            ) {
            
            isIntersect = TRUE;
            if (
                [enemyUnit state] != DEAD 
                && [enemyUnit state] != JUMP  
                ) {
                [self stopActionByTag:MOVEACTION];
            }
            
            if ([self coolDown] <= 0 
                && (
                    [enemyUnit state] != DEAD 
                    && [enemyUnit state] != CRY
                    //&& [enemyUnit state] != JUMP 
                    )
                ) { 
                [self stopActionByTag:MOVEACTION];
                [self setState:BATTLE];
                //[enemyUnit setState:CRY];
                
                [self updateAttackLogicWithUnit:enemyUnit];
                
                if([enemyUnit hitPoint]<=0){ 
                    // if enemy hp goes below 0 remove 
                    [enemyUnit setState:CRY];
                    [self setState:IDLE];
                    [self setFaceTexture:IDLE];
                }  //End attack
            } else if ( [enemyUnit state] == DEAD 
                       || [enemyUnit state] == CRY
                       || [enemyUnit hitPoint]<=0
                       //|| [enemyUnit state] == JUMP
                       ) {
                if ([self state] != WALK) {
                    [self setState:IDLE];
                    [self setFaceTexture:IDLE];
                }
                
            }
        }        
    }
    
    if (!isIntersect) {
        if([self isBattleStance]){
            //Move action is stopped and all parts are ready
            [self setState:IDLE];
            [self setFaceTexture:IDLE];
        }
        
    }
    
    if ([self numberOfRunningActions] == 0 || [self state] == WALK
        || [self state] == IDLE 
        ) {
        if (self.state == DEAD){
            [self.hpLabel setVisible:NO];
            return; // Nothing to do if the unit is dead
        }
        
        if (self.state == FINISHED) {
            [self.hpLabel setVisible:NO];
            [self setVisible:NO];
            return;
        } 
        
        if(self.state == BATTLE){
            if(self.numberOfRunningActions >0){
                //Still moving so stop move action
                [self stopActionByTag:MOVEACTION];
                return;
            }else if([self isAllPartsStopMoving]){
                //Move action is stopped and all parts are ready
                [self setBattleStance];
                [self animateBattle];
            }
        }
        
        if(self.state == WALK){
            if([self isAllPartsStopMoving]){
                //Continue animate walk if one cycle is ended
                [self animateWalk];
            }
        }
        
        if(self.state == IDLE){
            [self stopActionByTag:MOVEACTION];
            if(self.isBattleStance){
                //He is in battle stance, so change it back to normal
                
                [self setNormalStance];
            }else if([self numberOfRunningActions] == 0 
                     && [self isAllPartsStopMoving]){
                //Check self's action to ensure change on normal stance
                //Originally he will continue walking to goal
                
                [self setState:WALK];
                [self doMoveAction];
                
            }
        }
        
        if(self.state == CRY){
            [[self hpLabel] setVisible:NO];
            if([self isAllPartsStopMoving]){
                if(self.isBattleStance){
                    [self setNormalStance];
                }
                [self setFaceTexture:CRY];
                [self doFadeOut];
                [self setState:DEAD];
            }
            return;
        }
        
        if(self.state == FLIP) {
            [self stopActionByTag:MOVEACTION];
            return;
        }
    }
}

@end
