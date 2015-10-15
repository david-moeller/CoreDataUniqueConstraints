//
//  AppDelegate.m
//  CoreDataUniqueConstraints
//
//  Created by Zach Orr on 9/23/15.
//  Copyright © 2015 zorr. All rights reserved.
//

#import "AppDelegate.h"
#import "TableViewController.h"

@interface AppDelegate ()

@property BOOL migrationRequired;

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Pass our managed object context to our view controller
    UINavigationController *navController = (UINavigationController *)self.window.rootViewController;
    TableViewController *tableViewController = navController.viewControllers.firstObject;
    tableViewController.context = self.managedObjectContext;
    
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    // Saves changes in the application's managed object context before the application terminates.
    [self saveContext];
}

#pragma mark - Core Data stack

@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

- (NSURL *)applicationDocumentsDirectory {
    // The directory the application uses to store the Core Data store file. This code uses a directory named "com.zor.CoreDataUniqueConstraints" in the application's documents directory.
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}
- (NSURL *)modelURL {
    return [[NSBundle mainBundle] URLForResource:@"CoreDataUniqueConstraints" withExtension:@"momd"];
}
- (NSString *)storeType {
    return NSSQLiteStoreType;
}
- (NSString *)storeConfiguration {
    return nil;
}
- (NSURL *)storeURL {
    return [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"CoreDataUniqueConstraints.sqlite"];
}
- (NSDictionary *)storeOptions {
    return @{ NSMigratePersistentStoresAutomaticallyOption: @YES,
                    NSInferMappingModelAutomaticallyOption: @YES };
    
}
- (NSDictionary *)storeMetadata {
    
    NSError *__autoreleasing error = nil;
    NSDictionary* sourceMetadata = [NSPersistentStoreCoordinator metadataForPersistentStoreOfType:[self storeType]
                                                                                              URL:[self storeURL]
                                                                                          options:[self storeOptions]
                                                                                            error:&error];
    if (sourceMetadata == nil) {
        NSLog(@"Source metadata not found, with error: %@", error.localizedDescription);
    }
    return sourceMetadata;
}
- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:[self modelURL]];
    
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil &&
        [_persistentStoreCoordinator.managedObjectModel isEqual:[self managedObjectModel]]) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    NSLog(@"Creating new persistent store coordinator");
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSError *__autoreleasing error = nil;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:[self storeType]
                                                   configuration:[self storeConfiguration]
                                                             URL:[self storeURL]
                                                         options:[self storeOptions]
                                                           error:&error]) {
        NSLog(@"Failed to add persistent store with error: %@", error.localizedDescription);
        NSDictionary* sourceMetadata = self.storeMetadata;
        if (![[self managedObjectModel] isConfiguration:[self storeConfiguration]
                          compatibleWithStoreMetadata:sourceMetadata]) {
            NSLog(@"Setting migration is required.");
            // Migration or data sanitization is required.
            self.migrationRequired = YES;
            // Fall back on managed object model for existing data.
            NSLog(@"Falling back on existing metadata object model");
            NSManagedObjectModel* sourceModel =[NSManagedObjectModel mergedModelFromBundles:@[[NSBundle mainBundle]]
                                                                           forStoreMetadata:sourceMetadata];
            _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:sourceModel];
        } else {
            self.migrationRequired = NO;
        }
        
        NSLog(@"Re-attempt setup persistent store coordinator");
        NSError *__autoreleasing fallbackError = nil;
        if (![_persistentStoreCoordinator addPersistentStoreWithType:[self storeType]
                                                       configuration:[self storeConfiguration]
                                                                 URL:[self storeURL]
                                                             options:[self storeOptions]
                                                               error:&fallbackError]) {
        
            // Report any error we got.
            NSMutableDictionary *dict = [NSMutableDictionary dictionary];
            dict[NSLocalizedDescriptionKey] = @"Failed to initialize the application's saved data";
            dict[NSLocalizedFailureReasonErrorKey] = @"There was an error creating or loading the application's saved data.";
            dict[NSUnderlyingErrorKey] = fallbackError;
            error = [NSError errorWithDomain:@"YOUR_ERROR_DOMAIN" code:9999 userInfo:dict];
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", fallbackError, [fallbackError userInfo]);
            abort();
        }
    } else {
        self.migrationRequired = NO;
    }
    
    return _persistentStoreCoordinator;
}

- (NSFetchRequest *)requestForDuplicateObjectsInContext:(NSManagedObjectContext* __nonnull) moc {
    // Break this up!
    NSFetchRequest* objectsToKeepRequest = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
    NSExpressionDescription* ed = [[NSExpressionDescription alloc]init];
    ed.expression = [NSExpression expressionForEvaluatedObject];
    ed.name = @"SELF";
    ed.expressionResultType = NSObjectIDAttributeType;
    objectsToKeepRequest.propertiesToFetch = @[ed];
    
    objectsToKeepRequest.propertiesToGroupBy = @[@"name"];
    objectsToKeepRequest.resultType = NSDictionaryResultType;
    NSExpression* otkExpression = [NSExpression expressionForConstantValue:objectsToKeepRequest];
    NSExpression* mocExpression = [NSExpression expressionForConstantValue:moc];
    NSFetchRequest* duplicateObjectRequest = [NSFetchRequest fetchRequestWithEntityName:@"Person"];
    NSFetchRequestExpression* fre = (NSFetchRequestExpression*)[NSFetchRequestExpression expressionForFetch:otkExpression
                                                                         context:mocExpression
                                                                       countOnly:NO];
    duplicateObjectRequest.predicate = [NSPredicate predicateWithFormat:@"NOT SELF IN %@", fre];
    return duplicateObjectRequest;
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    
    if (self.migrationRequired) {
        NSManagedObjectContext* moc = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [moc setPersistentStoreCoordinator:coordinator];
        [moc setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
        [moc performBlockAndWait:^{
            NSBatchDeleteRequest* duplicateDeleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:[self requestForDuplicateObjectsInContext:moc]];
            duplicateDeleteRequest.resultType = NSBatchDeleteResultTypeCount;
            NSError*__autoreleasing error = nil;
            NSBatchDeleteResult* resultBox = [moc executeRequest:duplicateDeleteRequest error:&error];
            if (resultBox == nil) {
                NSLog(@"encountered error: %@", error);
                abort();
            }
            NSInteger deletedObjectCount = [resultBox.result integerValue];
            NSLog(@"Removed %ld duplicate objects", (long)deletedObjectCount);
            self.migrationRequired = NO;
        }];
    }
    
    coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    [_managedObjectContext setMergePolicy:NSMergeByPropertyObjectTrumpMergePolicy];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = [self managedObjectContext];
    if (managedObjectContext != nil) {
        NSError *__autoreleasing error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
