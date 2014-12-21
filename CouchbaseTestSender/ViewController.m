//
//  ViewController.m
//  CouchbaseTestSender
//
//  Created by Denis Dyukorev on 21/12/14.
//  Copyright (c) 2014 LI. All rights reserved.
//

#import "ViewController.h"
#import "CouchbaseLite/CouchbaseLite.h"
#import "CouchbaseLite/CBLDocument.h"

@interface ViewController ()
// shared manager
@property (strong, nonatomic) CBLManager *manager;
// the database
@property (strong, nonatomic) CBLDatabase *database;
@property (strong, nonatomic) CBLDatabase *receiverDatabase;

// document identifier
@property (strong, nonatomic) NSString *docID;
// username
@property (strong, nonatomic) NSString *username;
// password
@property (strong, nonatomic) NSString *password;

@property (nonatomic) CBLReplicationStatus lastStatus;
@property (nonatomic) CBLReplicationStatus lastReceiveStatus;

@property (strong, nonatomic) NSDate *lastTimeStatusChange;
@property (strong, nonatomic) NSDate *lastTimeReceiveChange;

@property (strong, nonatomic) NSString *userUUID;

@property (strong, nonatomic) CBLReplication *pushReplication;
@property (strong, nonatomic) CBLReplication *pullReplication;


- (IBAction)runTest:(id)sender;
- (IBAction)startReceiver:(id)sender;
- (IBAction)deleteRecevierDatabase:(id)sender;

- (void) replicationChanged: (NSNotification*)n;
- (void) receiverReplicationChanged: (NSNotification*)n;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _userUUID = @"779e402b-b052-4ed0-ba2b-55102f92f60a";
    [self createTheManager];
    [self createTheDatabase];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark Manager and Database Methods
// creates the manager object
- (BOOL) createTheManager {
    // create a shared instance of CBLManager
    _manager = [CBLManager sharedInstance];
    if (!_manager) {
        NSLog (@"Cannot create shared instance of CBLManager");
        return NO;
    }
    
    NSLog (@"Manager created");
    
    return YES;
}

// creates the database
- (BOOL) createTheDatabase {
    
    NSError *error;
    
    // create a name for the database and make sure the name is legal
    NSString *dbname = @"assay-test";
    if (![CBLManager isValidDatabaseName: dbname]) {
        NSLog (@"Bad database name");
        return NO;
    }
    
    NSString *dbnameReceiver = @"assay-test-receive";
    if (![CBLManager isValidDatabaseName: dbnameReceiver]) {
        NSLog (@"Bad database name");
        return NO;
    }
    
    // create a new database
    if (!_database) {
        _database = [_manager databaseNamed: dbname error: &error];
    
        if (!_database) {
            NSLog (@"Cannot create database. Error message: %@",
                   error.localizedDescription);
            return NO;
        }
    }
    
    if (!_receiverDatabase) {
        _receiverDatabase = [_manager databaseNamed: dbnameReceiver error: &error];
        if (!_receiverDatabase) {
            NSLog (@"Cannot create database. Error message: %@",
                   error.localizedDescription);
            return NO;
        }
    }
    
    // log the database location
    NSString *databaseLocation =
    [[[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]
     stringByAppendingString: @"/Library/Application Support/CouchbaseLite"];
    NSLog(@"Database %@ created at %@", dbname,
          [NSString stringWithFormat:@"%@/%@%@", databaseLocation, dbname, @".cblite"]);
    
    return YES;
}

- (BOOL) startReplication {
    NSURL* url = [NSURL URLWithString: @"http://ec2-54-69-26-176.us-west-2.compute.amazonaws.com:4984/assay_dev2"];
    _pushReplication = [_database createPushReplication: url];
    _pushReplication.continuous = YES;
    
    _username = @"slava4";
    _password = @"slava4";
    
    id<CBLAuthenticator> auth;
    auth = [CBLAuthenticator basicAuthenticatorWithName: _username
                                               password: _password];
    _pushReplication.authenticator = auth;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(replicationChanged:)
                                                 name: kCBLReplicationChangeNotification
                                               object: _pushReplication];
    
    [_pushReplication start];
    
    return YES;
}

- (BOOL) startReciverReplication {
    NSURL* url = [NSURL URLWithString: @"http://ec2-54-69-26-176.us-west-2.compute.amazonaws.com:4984/assay_dev2"];

    _pullReplication = [_database createPullReplication: url];
    _pullReplication.continuous = YES;
    
    _username = @"slava4";
    _password = @"slava4";
    
    id<CBLAuthenticator> auth;
    auth = [CBLAuthenticator basicAuthenticatorWithName: _username
                                               password: _password];
    _pullReplication.authenticator = auth;
    
    [[NSNotificationCenter defaultCenter] addObserver: self
                                             selector: @selector(receiverReplicationChanged:)
                                                 name: kCBLReplicationChangeNotification
                                               object: _pullReplication];
    
    [_pullReplication start];
    
    return YES;
}

- (void) replicationChanged: (NSNotification*)n {
    CBLReplication *replication = (CBLReplication *)n.object;
    
    if (replication.status != _lastStatus) {
        NSString * status = @"Unknown";
        
        switch (replication.status) {
            case kCBLReplicationActive:
                status = @"Active";
                break;
            case kCBLReplicationIdle:
                status = @"Idle";
                break;
            case kCBLReplicationOffline:
                status = @"Offline";
                break;
            case kCBLReplicationStopped:
                status = @"Stoped";
                break;
            default:
                break;
        }
        
        NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000];
        NSLog(@"Push status changed to %@ at %@", status, timestamp);
    }
    
    _lastStatus = replication.status;
}

- (void) receiverReplicationChanged: (NSNotification*)n {
    CBLReplication *replication = (CBLReplication *)n.object;
    
    if (replication.status != _lastReceiveStatus) {
        NSString * status = @"Unknown";
        
        switch (replication.status) {
            case kCBLReplicationActive:
                status = @"Active";
                break;
            case kCBLReplicationIdle:
                status = @"Idle";
                break;
            case kCBLReplicationOffline:
                status = @"Offline";
                break;
            case kCBLReplicationStopped:
                status = @"Stoped";
                break;
            default:
                break;
        }
        
        NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000];
        NSLog(@"Pull status changed to %@ at %@", status, timestamp);
    }
    
    _lastReceiveStatus = replication.status;
}


#pragma mark CRUD Methods
// creates the document
- (BOOL) createTheDocument {
    NSDictionary* properties = @{@"property1": [NSString stringWithFormat:@"property1Value %@", [[NSUUID UUID] UUIDString]],
                                 @"property2": [NSString stringWithFormat:@"property2Value %@", [[NSUUID UUID] UUIDString]],
                                 @"property3": [NSString stringWithFormat:@"property3Value %@", [[NSUUID UUID] UUIDString]],
                                 @"property4": [NSString stringWithFormat:@"property4Value %@", [[NSUUID UUID] UUIDString]],
                                 @"property5": [NSString stringWithFormat:@"property5Value %@", [[NSUUID UUID] UUIDString]],
                                 @"property6": [NSString stringWithFormat:@"property6Value %@", [[NSUUID UUID] UUIDString]],
                                 @"property7": [NSString stringWithFormat:@"property7Value %@", [[NSUUID UUID] UUIDString]],
                                 @"property8": [NSString stringWithFormat:@"property8Value %@", [[NSUUID UUID] UUIDString]],
                                 @"property9": [NSString stringWithFormat:@"property9Value %@", [[NSUUID UUID] UUIDString]],
                                 @"property10": [NSString stringWithFormat:@"property10Value %@", [[NSUUID UUID] UUIDString]],
                                 @"channels":    @[_userUUID]};
    CBLDocument* document = [_database createDocument];
    NSError* error;
    if (![document putProperties: properties error: &error]) {
        NSLog(@"Error create document %@", error.description);
        return NO;
    }
    return YES;
}
// retrieves the document
- (BOOL) retrieveTheDocument {return YES;}
// updates the document
- (BOOL) updateTheDocument {return YES;}
// deletes the document
- (BOOL) deleteTheDocument {return YES;}



- (IBAction)runTest:(id)sender {
    NSString * timestamp = [NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970] * 1000];
    NSLog (@"This Hello From RunTest action at %@", timestamp);
    [self startReplication];
    
    BOOL (^test100docsBlock)(void) = ^{
        for (int i=0; i<1; i++) {
            [self createTheDocument];
        }
        return YES;
    };
    
    [_database inTransaction: test100docsBlock];
}

- (IBAction)startReceiver:(id)sender {
    [self startReciverReplication];
}

- (IBAction)deleteRecevierDatabase:(id)sender {
    NSError* error;
    if (![_receiverDatabase deleteDatabase: &error]) {
        NSLog(@"Database delete error %@", error.description);
    } else {
        NSLog(@"Database deleted successful");
    }
    _receiverDatabase = nil;
    [self createTheDatabase];
}

@end
