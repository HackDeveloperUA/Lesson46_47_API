//
//  ASServerManager.m
//  HW_46_47
//
//  Created by MD on 11.09.15.
//  Copyright (c) 2015 MD. All rights reserved.
//

#import "ASServerManager.h"
#import "AFNetworking.h"
#import "ASLoginVC.h"
#import "ASAccessToken.h"

#import "ASUser.h"
#import "ASGroup.h"
#import "ASWall.h"
#import "ASPhoto.h"
#import "ASComment.h"
#import "ASFriend.h"
#import "ASSubscription.h"
#import "ASAudio.h"


static NSString* kToken = @"kToken";
static NSString* kExpirationDate = @"kExpirationDate";
static NSString* kUserId = @"kUserId";



@interface ASServerManager ()

@property (strong, nonatomic) AFHTTPRequestOperationManager* requestOperationManager;
@property (strong, nonatomic) ASAccessToken* accessToken;
@property (strong,nonatomic) dispatch_queue_t requestQueue;

@end

@implementation ASServerManager


#pragma mark - INIT SINGLETONE



+ (ASServerManager*) sharedManager {
    
    static ASServerManager* manager = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[ASServerManager alloc] init];
    });
    
    return manager;
}


- (instancetype)init {
    
    self = [super init];
    if (self) {
        self.requestQueue = dispatch_queue_create("iOSDevCourse.requestVk", DISPATCH_QUEUE_PRIORITY_DEFAULT);
        self.requestOperationManager = [[AFHTTPRequestOperationManager alloc]initWithBaseURL:[NSURL URLWithString:@"https://api.vk.com/method/"]];
        self.accessToken = [[ASAccessToken alloc]init];
        [self loadSettings];
    }
    return self;
}








#pragma mark - SAVE SETTING

////////////////////////////////////////
//
//  SAVE SETTING
//
////////////////////////////////////////


- (void)saveSettings:(ASAccessToken *)token {
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:token.token forKey:kToken];
    [userDefaults setObject:token.expirationDate forKey:kExpirationDate];
    [userDefaults setObject:token.userID forKey:kUserId];
    [userDefaults synchronize];
}






////////////////////////////////////////
//
//  LOAD SETTING
//
////////////////////////////////////////


- (void)loadSettings {
    
    NSUserDefaults* userDefaults = [NSUserDefaults standardUserDefaults];
    self.accessToken.token = [userDefaults objectForKey:kToken];
    self.accessToken.expirationDate = [userDefaults objectForKey:kExpirationDate];
    self.accessToken.userID = [userDefaults objectForKey:kUserId];
    
}






////////////////////////////////////////
//
//  AUTHORIZE USER
//
////////////////////////////////////////



- (void)authorizeUser:(void(^)(ASUser* user))completion {
    
    if ([self.accessToken.expirationDate compare:[NSDate date]] == NSOrderedDescending) {
        
        [self getUsersInfoUserID:self.accessToken.userID onSuccess:^(ASUser *user) {
            if (completion) {
                completion(user);
            }
        } onFailure:^(NSError *error, NSInteger statusCode) {
            if (completion) {
                completion(nil);
            }
        }];
        
        
    } else {
        
        ASLoginVC* vc = [[ASLoginVC alloc] initWithCompletionBlock:^(ASAccessToken *token) {
            
            [self saveSettings:token];
            self.accessToken = token;
            
            if (token) {
                
                [self getUsersInfoUserID:self.accessToken.userID onSuccess:^(ASUser *user) {
                    if (completion) {
                        completion(user);
                    }
                } onFailure:^(NSError *error, NSInteger statusCode) {
                    if (completion) {
                        completion(nil);
                    }
                }];
                
            } else if (completion) {
                completion(nil);
            }
            
        }];
        
        UINavigationController* nav = [[UINavigationController alloc] initWithRootViewController:vc];
        
        UIViewController* mainVC = [[[[UIApplication sharedApplication] windows] firstObject] rootViewController];
        
        [mainVC presentViewController:nav animated:YES completion:nil];
        
    }
}











#pragma mark - GET USER INFO

////////////////////////////////////////
//
//  GET USER INFO
//
////////////////////////////////////////



- (void) getUsersInfoUserID:(NSString*) userId
                  onSuccess:(void(^)(ASUser* user)) success
                  onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            userId,      @"user_ids",
                            @"sex,"
                            "bdate,"
                            "city,"
                            "country,"
                            "photo_max_orig,"
                            "online,"
                            "photo_id,"
                            "can_post,"
                            "can_write_private_message,"
                            "status,"
                            "last_seen,"
                            "counters,"
                            "friend_status,"
                            "personal",  @"fields",
                            @"nom",      @"name_case",
                            @"5.37",     @"v",
                            self.accessToken.token, @"access_token",nil];
    
    
    
    [self.requestOperationManager GET:@"users.get"
                           parameters:params
     
                              success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
                                  

                                  NSArray* responceArray = [responseObject objectForKey:@"response"];
                                  ASUser* user = nil;
                                  
                                  for (NSDictionary* dict in responceArray) {
                                      user = [[ASUser alloc] initWithServerResponse:dict];
                                  }
                                  
                                  
                              if (success) {
                                  success(user);
                              }
                          }
     
                              failure:^(AFHTTPRequestOperation *operation, NSError* error){
                                  
                                  NSLog(@"Error: %@",error);
                                  if (failure) {
                                      failure(error, operation.response.statusCode);
                                  }
                              }];
}









#pragma mark - GET USER PHOTOS


////////////////////////////////////////
//
//  GET USER PHOTOS
//
////////////////////////////////////////



-(void) getPhotoUserID:(NSString*) userID
            withOffset:(NSInteger) offset
                 count:(NSInteger) count
             onSuccess:(void(^)(NSArray* photos)) success
             onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            userID,      @"owner_id",
                            @"wall",     @"album_id",
                            //@"",         @"photo_ids",
                            @"1",        @"rev",
                            @"1",        @"extended",
                            // @"photo",    @"feed_type",
                            //@"0",        @"photo_sizes",
                            @(offset),   @"offset",
                            @(count),    @"count",
                            @"5.37",     @"v",
                            self.accessToken.token, @"access_token",nil];
    
    
    [self.requestOperationManager GET:@"photos.get"
                           parameters:params
     
                              success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
                                  
                               NSArray*  items    = [[responseObject objectForKey:@"response"] objectForKey:@"items"];
                                  
                                  NSMutableArray* objectsArray = [NSMutableArray array];

                                  for (NSDictionary* dict in items) {
                                      
                                      ASPhoto* photo = [[ASPhoto alloc] initWithServerResponse:dict];
                                      [objectsArray addObject:photo];
                                  }
                                  
                                  
                                  if (success) {
                                      success(objectsArray);
                                  }
                              }
     
                              failure:^(AFHTTPRequestOperation *operation, NSError* error){
                                  NSLog(@"Error: %@",error);
                                  if (failure) {
                                      failure(error, operation.response.statusCode);
                                  }
                              }];
    
}










#pragma mark - GET COUNTERES

////////////////////////////////////////
//
//  GET COUNTERES
//
////////////////////////////////////////



- (void)getCounteresInfoByID:(NSString *)ids
                   onSuccess:(void (^) (NSString *country)) success
                   onFailure:(void (^) (NSError *error)) failure {
    
    NSDictionary *paramDictionary = [NSDictionary dictionaryWithObjectsAndKeys:ids,@"country_ids", nil];
    
    [self.requestOperationManager GET:@"database.getCountriesById" parameters:paramDictionary
                              success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                  
                                  NSArray *objects =   [responseObject objectForKey:@"response"];
                                  NSString* country = [[objects firstObject] objectForKey:@"name"];
                                  
                                  success(country);
                                  
                              } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                  failure(error);
                              }];
    
}





////////////////////////////////////////
//
//  GET CITY BY ID
//
////////////////////////////////////////


- (void)getCityInfoByID:(NSString *)ids
              onSuccess:(void (^) (NSString *city)) success
              onFailure:(void (^) (NSError *error)) failure {
    
    NSDictionary *paramDictionary = [NSDictionary dictionaryWithObjectsAndKeys:ids,@"city_ids", nil];
    
    [self.requestOperationManager GET:@"database.getCitiesById" parameters:paramDictionary success:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSArray *objects = [responseObject objectForKey:@"response"];
        NSString* city = [[objects firstObject] objectForKey:@"name"];
        
        success(city);
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        failure(error);
    }];
    
}













#pragma mark - GET GROUP INFO

////////////////////////////////////////
//
//  GET GROUP INFO
//
////////////////////////////////////////



- (void) getGroupInfoID:(NSString*) groupId
              onSuccess:(void(^)(ASGroup* group)) success
              onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            groupId,                @"group_id",
                            @"status,activity,can_post,members_count,counters,description", @"fields",
                            @"5.37", @"v",
                            self.accessToken.token, @"access_token" ,nil];
    
    
    [self.requestOperationManager GET:@"groups.getById"
                           parameters:params
     
                              success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
                                  
                                //  NSLog(@"groups.getById JSON: %@",responseObject);
                                  
                                  NSArray* friendsArray = [responseObject objectForKey:@"response"];
                                  ASGroup* group = nil;
                                  
                                  for (NSDictionary* dict in friendsArray) {
                                      group = [[ASGroup alloc] initWithServerResponse:dict];
                                  }
                                  
                                  
                                  if (success) {
                                      success(group);
                                  }
                              }
     
                              failure:^(AFHTTPRequestOperation *operation, NSError* error){
                                  
                                  NSLog(@"Error: %@",error);
                                  if (failure) {
                                      failure(error, operation.response.statusCode);
                                  }
                              }];
  
}








#pragma mark - ADD POST ON WALL  / GET WALL


////////////////////////////////////////
//
//   ADD POST
//
////////////////////////////////////////


-(void) addPostOnWall:(NSString*) ownerID
          withMessage:(NSString*) message
            onSuccess:(void(^)(NSDictionary* result)) success
            onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            ownerID,            @"owner_id",
                            @"0",          @"friends_only",
                            @"",          @"from_group",
                            message,       @"message",
                            @"",           @"attachments",
                            
                            @"",           @"services",
                            @"0",          @"signed",
                            @"0",           @"publish_date",
                            @"",           @"lat",
                            @"",           @"long",
                            @"",           @"place_id",
                            @"",           @"post_id",
                            @"5.37",      @"v",
                            self.accessToken.token, @"access_token", nil];
    
    
    [self.requestOperationManager POST:@"wall.post" parameters:params success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        
        
        if (success) {
            success(responseObject);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error, operation.response.statusCode);
        }
    }];
    
}





////////////////////////////////////////
//
//   GET WALL
//
////////////////////////////////////////


- (void)  getWall:(NSString*) ownerID
       withDomain:(NSString*) domain
       withFilter:(NSString*) filter
       withOffset:(NSInteger) offset
        typeOwner:(NSString*) typeOwner
            count:(NSInteger) count
        onSuccess:(void(^)(NSArray* posts)) success
        onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {



    if ([typeOwner isEqualToString:@"group"]) {
        
        if (![ownerID hasPrefix:@"-"]) {
            ownerID = [@"-" stringByAppendingString:ownerID];
        }

    }
    
    NSMutableDictionary* params =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     ownerID,       @"owner_id",
     @"",           @"domain",
     @(count),      @"count",
     @(offset),     @"offset",
     filter,        @"filter",
     @"1",          @"extended",
     @"5.37",       @"v",
     self.accessToken.token, @"access_token", nil];
    
    
    
    [self.requestOperationManager  GET:@"wall.get"
                            parameters:params
                               success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
                                                                      
                                   
                    dispatch_async(self.requestQueue, ^{
 
                                   
                   NSArray*   wallArray     = [[responseObject objectForKey:@"response"] objectForKey:@"items"];
                   NSArray*   profilesArray = [[responseObject objectForKey:@"response"] objectForKey:@"profiles"];
                   NSArray*   groupArray    = [[responseObject objectForKey:@"response"] objectForKey:@"groups"];

                   NSMutableArray *arrayWithProfiles = [[NSMutableArray alloc]init];
                  
                   NSMutableDictionary* profilesBase = [NSMutableDictionary dictionary];
                   NSMutableDictionary* groupsBase   = [NSMutableDictionary dictionary];

                   if (wallArray) {
                   
                       
                       for (NSDictionary* dict in profilesArray) {
                           [profilesBase setValue:dict forKey:[[dict objectForKey:@"id"] stringValue]];
                       }
                       
                       for (NSDictionary* dict in groupArray) {
                      
                           NSString* key = [[dict objectForKey:@"id"] stringValue];
                           if (![key hasPrefix:@"-"]) {
                               key = [@"-" stringByAppendingString:key];
                           }
                           [groupsBase setValue:dict forKey:key];
                       }
                     
                       
                       
           for (int i=0; i<[wallArray count]; i++) {
               
               NSDictionary* dictItem    = wallArray[i];
               ASWall* wall = [[ASWall alloc] initWithServerResponse:dictItem];
               
               
               if (![wall.fromID hasPrefix:@"-"]) {
                   wall.user = [[ASUser alloc] initWithServerResponse:[profilesBase objectForKey:wall.fromID]];
               } else {
                 wall.group = [[ASGroup alloc] initWithServerResponse:[groupsBase objectForKey:wall.ownerID]];

               }
               
               [arrayWithProfiles addObject:wall];
           }
                 
                   }
    
                   dispatch_async(dispatch_get_main_queue(), ^{

                       if (success) {
                           success(arrayWithProfiles);
                       }
                   });
            });
                               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                   NSLog(@"Error: %@", error);
                                   
                                   if (failure) {
                                       failure(error, operation.response.statusCode);
                                   }
                               }];
   
}












#pragma mark - ADD LIKE ON POST / DELETE LIKE FROM POST


////////////////////////////////////////
//
//  ADD LIKE
//
////////////////////////////////////////


- (void) postAddLikeOnWall:(NSString*)ownerID
                    inPost:(NSString*)postID
                      type:(NSString *)type
                 typeOwner:(NSString*) typeOwner
                 onSuccess:(void(^)(NSDictionary* result))success
                 onFailure:(void(^)(NSError* error, NSInteger statusCode))failure {
    
    
    
    if ([typeOwner isEqualToString:@"group"]) {
        
        if (![ownerID hasPrefix:@"-"]) {
            ownerID = [@"-" stringByAppendingString:ownerID];
        }
        
    }

    
    NSDictionary *parameters = @{@"type"            : type,
                                 @"owner_id"        : ownerID,
                                 @"item_id"         : postID,
                                 @"v"               : @"5.37",
                                 @"ref"             : @"",
                                 @"access_token"    : self.accessToken.token };
    
   
    [self.requestOperationManager POST:@"likes.add" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        
        
        if (success) {
            success(responseObject);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (failure) {
            failure(error, operation.response.statusCode);
        }
    }];

}








////////////////////////////////////////
//
//  DELETE LIKE
//
////////////////////////////////////////



- (void) postDeleteLikeOnWall:(NSString*)ownerID
                       inPost:(NSString*)postID
                         type:(NSString *)type
                    typeOwner:(NSString*) typeOwner
                    onSuccess:(void(^)(NSDictionary* result))success
                    onFailure:(void(^)(NSError* error, NSInteger statusCode))failure {
    

    if ([typeOwner isEqualToString:@"group"]) {
        
        if (![ownerID hasPrefix:@"-"]) {
            ownerID = [@"-" stringByAppendingString:ownerID];
        }
        
    }


    NSDictionary *parameters = @{@"type"            : type,
                                 @"owner_id"        : ownerID,
                                 @"item_id"         : postID,
                                 @"v"               : @"5.37",
                                 @"access_token"    : self.accessToken.token };
    
    [self.requestOperationManager POST:@"likes.delete" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        
        if (success) {
            success(responseObject);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error, operation.response.statusCode);
        }
    }];
    
}












#pragma mark - REPOST




////////////////////////////////////////
//
//  REPOST
//
////////////////////////////////////////



- (void)repostOnMyWall:(NSString*)ownerID
                inPost:(NSString*)postID
           withMessage:(NSString*)message
             typeOwner:(NSString*) typeOwner
             onSuccess:(void(^)(NSDictionary* result))success
             onFailure:(void(^)(NSError* error, NSInteger statusCode))failure {
    

    
    if ([typeOwner isEqualToString:@"group"]) {
        
        if (![ownerID hasPrefix:@"-"]) {
            ownerID = [@"-" stringByAppendingString:ownerID];
        }
        
    }
    
    
    NSString *object = [NSString stringWithFormat:@"wall%@_%@",ownerID,postID];
    
    NSDictionary *parameters = @{@"object"          : object,
                                 @"message"         : message,
                                 @"v"               : @"5.37",
                                 @"ref"             : @"",
                                 @"access_token"    : self.accessToken.token };
    
    [self.requestOperationManager POST:@"wall.repost" parameters:parameters success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        
        
        
        if (success) {
            success(responseObject);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        
        if (failure) {
            failure(error, operation.response.statusCode);
        }
    }];
}












#pragma mark - GET COMMENTS


////////////////////////////////////////
//
//  GET COMMENTS
//
////////////////////////////////////////




-(void) getCommentFromPost:(NSString*) ownerID
                    inPost:(NSString*) postID
                 typeOwner:(NSString*) typeOwner
                withOffset:(NSInteger) offset
                     count:(NSInteger) count
                 onSuccess:(void(^)(NSArray* comments)) success
                 onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    
    if ([typeOwner isEqualToString:@"group"]) {
        
        if (![ownerID hasPrefix:@"-"]) {
            ownerID = [@"-" stringByAppendingString:ownerID];
        }
        
    }
    
    
    NSMutableDictionary* params =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     ownerID,       @"owner_id",
     postID ,       @"post_id",
     
     @"1",          @"need_likes",
     //@"asc",        @"sort",
      @"desc",       @"sort",
     @"0",          @"preview_length",
     @(count),      @"count",
     @(offset),     @"offset",
     @"1",          @"extended",
     @"5.37",       @"v",
     self.accessToken.token, @"access_token", nil];
    
    
 
    
    [self.requestOperationManager  GET:@"wall.getComments"
                            parameters:params
                               success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
                                   
                                   
                                   
                                   dispatch_async(self.requestQueue, ^{
                                       
                                       
                                       NSArray*   commentArray  = [[responseObject objectForKey:@"response"] objectForKey:@"items"];
                                       NSArray*   profilesArray = [[responseObject objectForKey:@"response"] objectForKey:@"profiles"];
                                       NSArray*   groupArray    = [[responseObject objectForKey:@"response"] objectForKey:@"groups"];
                                       
                                       NSMutableArray *arrayWithComment = [[NSMutableArray alloc]init];
                                       
                                       NSMutableDictionary* profilesBase = [NSMutableDictionary dictionary];
                                       
                                       
                                       if (commentArray) {
                                           
                                           
                                           for (NSDictionary* dict in profilesArray) {
                                               [profilesBase setValue:dict forKey:[[dict objectForKey:@"id"] stringValue]];
                                           }
                                           
                                      
                                           
                                           for (int i=[commentArray count]-1; i>=0; i--) {
                                               
                                               NSDictionary* dictItem    = commentArray[i];
                                               ASComment* comment = [[ASComment alloc] initWithServerResponse:dictItem];
                                               
                                               if (![comment.fromID hasPrefix:@"-"]) {
                                                   comment.user = [[ASUser alloc] initWithServerResponse:[profilesBase objectForKey:comment.fromID]];
                                               } else {
                                                   comment.group = [[ASGroup alloc] initWithServerResponse:[groupArray firstObject]];  }
                                               
                                               [arrayWithComment addObject:comment];
                                           }
                                           
                                           
                                       }
                                       
                                       dispatch_async(dispatch_get_main_queue(), ^{
                                           
                                           if (success) {
                                               success(arrayWithComment);
                                           }
                                       });
                                   });
                                   

                               } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                   NSLog(@"Error: %@", error);
                                   
                                   if (failure) {
                                       failure(error, operation.response.statusCode);
                                   }
                               }];

}







#pragma mark - JOIN IN GROUP / LEAVE FROM GROUP


////////////////////////////////////////
//
//  JOIN IN GROUP
//
////////////////////////////////////////



-(void) joinToGroup:(NSString*) groupID
          onSuccess:(void(^)(NSDictionary* result))success
          onFailure:(void(^)(NSError* error, NSInteger statusCode))failure {
    
    
    NSMutableDictionary* params =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     groupID,      @"group_id",
     @"0" ,        @"not_sure",
     @"5.37",      @"v",
     self.accessToken.token, @"access_token", nil];

    
    [self.requestOperationManager POST:@"groups.join" parameters:params success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        
        if (success) {
            success(responseObject);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error, operation.response.statusCode);
        }
    }];

    
}








////////////////////////////////////////
//
//  LEAVE FROM GROUP
//
////////////////////////////////////////


-(void) leaveFromGroup:(NSString*) groupID
             onSuccess:(void(^)(NSDictionary* result))success
             onFailure:(void(^)(NSError* error, NSInteger statusCode))failure {
    
 
    NSMutableDictionary* params =
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     groupID,      @"group_id",
     @"5.37",      @"v",
     self.accessToken.token, @"access_token", nil];
    

    [self.requestOperationManager POST:@"groups.leave" parameters:params success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        
        if (success) {
            success(responseObject);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error, operation.response.statusCode);
        }
    }];
 
}










#pragma mark - ADD FRIENDS / DELETE FREIENDS

////////////////////////////////////////
//
//  ADD FRIENDS
//
////////////////////////////////////////


-(void) addToFriends:(NSString*) userId
           onSuccess:(void(^)(NSDictionary* result))success
           onFailure:(void(^)(NSError* error, NSInteger statusCode))failure {
    
   
    NSMutableDictionary* params =
  
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     userId,                @"user_id",
     @"Add me in friends",  @"text",
     @"1",                  @"follow",
     @"5.37",               @"v",
     self.accessToken.token, @"access_token", nil];
    
    
 [self.requestOperationManager POST:@"friends.add" parameters:params success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        
        if (success) {
            success(responseObject);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error, operation.response.statusCode);
        }
    }];

    
}







////////////////////////////////////////
//
//  DELETE FRIENDS
//
////////////////////////////////////////


-(void) deleteFromFriends:(NSString*) userId
                onSuccess:(void(^)(NSDictionary* result))success
                onFailure:(void(^)(NSError* error, NSInteger statusCode))failure {
    
    
    NSMutableDictionary* params =
    
    [NSMutableDictionary dictionaryWithObjectsAndKeys:
     userId,                 @"user_id",
     @"5.37",                @"v",
     self.accessToken.token, @"access_token", nil];
    
    
    [self.requestOperationManager POST:@"friends.delete" parameters:params success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
        
        if (success) {
            success(responseObject);
        }
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (failure) {
            failure(error, operation.response.statusCode);
        }
    }];
}












#pragma mark - GET FRIENDS / SUBSCRIPTION


////////////////////////////////////////
//
//  GET FRIENDS
//
////////////////////////////////////////




- (void) getFriendsWithOffset:(NSString*) userId
                   withOffset:(NSInteger) offset
                    withCount:(NSInteger) count
                    onSuccess:(void(^)(NSArray* friends)) success
                    onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    

    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            userId, @"user_id",
                            //@"hints",     @"order",
                            @"name",     @"order",
                            @(count),     @"count",
                            @(offset),    @"offset",
                            @"photo_100,city,status",  @"fields",
                            @"nom",       @"name_case",
                            @"5.37",      @"v",
                            self.accessToken.token, @"access_token", nil];

    
    
    
    [self.requestOperationManager GET:@"friends.get"
                           parameters:params
     
                              success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
                                  
                                  
                                  NSArray* friendsArray = [[responseObject objectForKey:@"response"] objectForKey:@"items"];
                                  NSMutableArray* objectsArray = [NSMutableArray array];
                                  
                                  
                                  for (NSDictionary* dict in friendsArray) {
                                      
                                      ASFriend* friend = [[ASFriend alloc] initWithServerResponse:dict];
                                      [objectsArray addObject:friend];
                                  }
                                  
                                  
                                  if (success) {
                                      success(objectsArray);
                                  }
                              }
     
     
                              failure:^(AFHTTPRequestOperation *operation, NSError* error){
                                  NSLog(@"Error: %@",error);
                                  if (failure) {
                                      failure(error, operation.response.statusCode);
                                  }
                              }];
}












////////////////////////////////////////
//
//  GET SUBSCRIPTION
//
////////////////////////////////////////



- (void) getSubscriptionsWithId:(NSString*) userId
                       onOffSet:(NSInteger) offset
                          count:(NSInteger) count
                      onSuccess:(void(^)(NSArray* subcriptions)) success
                      onFailure:(void(^)(NSError* error, NSInteger statusCode)) failure {
    
    
    
    
    NSDictionary* params = [NSDictionary dictionaryWithObjectsAndKeys:
                            userId,        @"user_id",
                            @"1",          @"extended",
                            @(offset),     @"offset",
                            @(count),      @"count",
                            @"members_count,photo_100,status",  @"fields",
                            @"5.37",      @"v",
                            self.accessToken.token, @"access_token", nil];
    
    
    [self.requestOperationManager GET:@"users.getSubscriptions"
                           parameters:params
     
                              success:^(AFHTTPRequestOperation *operation, NSDictionary* responseObject) {
                                  
                                  NSLog(@"users.getSubscriptions JSON: %@",responseObject);
                                  
                                  
                              NSArray* subcriptArray = [[responseObject objectForKey:@"response"] objectForKey:@"items"];
                              NSMutableArray* objectsArray = [NSMutableArray array];
                              
                              
                              for (NSDictionary* dict in subcriptArray) {
                                  
                                  ASSubscription* subscript = [[ASSubscription alloc] initWithServerResponse:dict];
                                  [objectsArray addObject:subscript];
                              }
                              
                                  if (success) {
                                      success(objectsArray);
                                  }
                              }
     
                              failure:^(AFHTTPRequestOperation *operation, NSError* error){
                                  NSLog(@"Error: %@",error);
                                  if (failure) {
                                      failure(error, operation.response.statusCode);
                                  }
                              }];
    
}




@end
