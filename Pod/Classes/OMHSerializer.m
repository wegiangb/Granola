#import <ObjectiveSugar/ObjectiveSugar.h>
#import "OMHSerializer.h"
#import "NSDate+RFC3339.h"

@interface OMHSerializer()
@property (nonatomic, retain) HKSample* sample;
+ (NSDictionary*)typeIdentifiersToClasses;
+ (BOOL)canSerialize:(HKSample*)sample error:(NSError**)error;
+ (NSException*)unimplementedException;
@end


@implementation OMHSerializer

+ (NSDictionary*)typeIdentifiersToClasses {
  static NSDictionary* typeIdsToClasses = nil;
  if (typeIdsToClasses == nil) {
    typeIdsToClasses = @{
      HKQuantityTypeIdentifierHeight : @"OMHSerializerHeight",
      HKQuantityTypeIdentifierBodyMass : @"OMHSerializerWeight",
      HKQuantityTypeIdentifierStepCount : @"OMHSerializerStepCount",
      HKQuantityTypeIdentifierHeartRate : @"OMHSerializerHeartRate",
      HKQuantityTypeIdentifierBloodGlucose : @"OMHSerializerBloodGlucose",
      HKQuantityTypeIdentifierBasalEnergyBurned: @"OMHSerializerEnergyBurned",
      HKQuantityTypeIdentifierActiveEnergyBurned: @"OMHSerializerEnergyBurned",
      HKCategoryTypeIdentifierSleepAnalysis : @"OMHSerializerSleepAnalysis",
    };
  }
  return typeIdsToClasses;
}

+ (NSArray*)supportedTypeIdentifiers {
  return [[self typeIdentifiersToClasses] allKeys];
}

+ (BOOL)canSerialize:(HKSample*)sample error:(NSError**)error {
  @throw [self unimplementedException];
}

+ (id)forSample:(HKSample*)sample error:(NSError**)error {
  NSParameterAssert(sample);
  NSArray* supportedTypeIdentifiers = [self supportedTypeIdentifiers];
  NSString* sampleTypeIdentifier = sample.sampleType.identifier;
  if ([supportedTypeIdentifiers includes:sampleTypeIdentifier]) {
    NSString* serializerClassName =
      [self typeIdentifiersToClasses][sampleTypeIdentifier];
    Class serializerClass = NSClassFromString(serializerClassName);
    if ([serializerClass canSerialize:sample error:error]) {
      return [[serializerClass alloc] initWithSample:sample];
    }
  } else {
    if (error) {
      NSString* errorMessage =
        [NSString stringWithFormat: @"Unsupported HKSample type: %@",
        sampleTypeIdentifier];
      NSDictionary* userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
      *error = [NSError errorWithDomain: OMHErrorDomain
                                   code: OMHErrorCodeUnsupportedType
                               userInfo: userInfo];
    }
  }
  return nil;
}

- (id)initWithSample:(HKSample*)sample {
  self = [super init];
  if (self) {
    _sample = sample;
  } else {
    return nil;
  }
  return self;
}

- (NSString*)jsonOrError:(NSError**)serializationError {
  NSData *jsonData =
    [NSJSONSerialization dataWithJSONObject:[self data]
                                    options:NSJSONWritingPrettyPrinted
                                      error:serializationError];
  if (jsonData) {
    NSString *jsonString =
      [[NSString alloc] initWithData:jsonData
                            encoding:NSUTF8StringEncoding];
    return jsonString;
  } else {
    // serialization error populated, return nil
    return nil;
  }
}

#pragma mark - Private

- (id)data {
  return @{
    @"header": @{
      @"id": self.sample.UUID.UUIDString,
      @"creation_date_time": [self.sample.startDate RFC3339String],
      @"schema_id": @{
        @"namespace": @"omh",
        @"name": [self schemaName],
        @"version": @"1.0"
      },
    },
    @"body": [self bodyData]
  };
}

- (NSString*)schemaName {
  @throw [[self class] unimplementedException];
}

- (id)bodyData {
  @throw [[self class] unimplementedException];
}

+ (NSException*)unimplementedException {
  return [NSException exceptionWithName:NSInternalInconsistencyException
                                 reason:[NSString stringWithFormat:@"You must override %@ in a subclass", NSStringFromSelector(_cmd)]
                               userInfo:nil];
}

@end

@interface OMHSerializerStepCount : OMHSerializer; @end;
@implementation OMHSerializerStepCount
+ (BOOL)canSerialize:(HKQuantitySample*)sample error:(NSError**)error {
  return YES;
}
- (id)bodyData {
  HKUnit* unit = [HKUnit unitFromString:@"count"];
  double value =
    [[(HKQuantitySample*)self.sample quantity] doubleValueForUnit:unit];
  return @{
    @"step_count": [NSNumber numberWithDouble:value],
    @"effective_time_frame": @{
      @"start_date_time": [self.sample.startDate RFC3339String],
      @"end_date_time": [self.sample.endDate RFC3339String]
    }
  };
}
- (NSString*)schemaName {
  return @"step-count";
}
@end

@interface OMHSerializerHeight : OMHSerializer; @end;
@implementation OMHSerializerHeight
+ (BOOL)canSerialize:(HKQuantitySample*)sample error:(NSError**)error {
  return YES;
}
- (id)bodyData {
  NSString* unitString = @"cm";
  HKUnit* unit = [HKUnit unitFromString:unitString];
  double value =
    [[(HKQuantitySample*)self.sample quantity] doubleValueForUnit:unit];
  return @{
    @"body_height": @{
      @"value": [NSNumber numberWithDouble:value],
      @"unit": unitString
    },
    @"effective_time_frame": @{
      @"start_date_time": [self.sample.startDate RFC3339String],
      @"end_date_time": [self.sample.endDate RFC3339String]
    }
  };
}
- (NSString*)schemaName {
  return @"body-height";
}
@end

@interface OMHSerializerWeight : OMHSerializer; @end;
@implementation OMHSerializerWeight
+ (BOOL)canSerialize:(HKQuantitySample*)sample error:(NSError**)error {
  return YES;
}
- (id)bodyData {
  NSString* unitString = @"lb";
  HKUnit* unit = [HKUnit unitFromString:unitString];
  double value =
    [[(HKQuantitySample*)self.sample quantity] doubleValueForUnit:unit];
  return @{
    @"body_weight": @{
      @"value": [NSNumber numberWithDouble:value],
      @"unit": unitString
    },
    @"effective_time_frame": @{
      @"start_date_time": [self.sample.startDate RFC3339String],
      @"end_date_time": [self.sample.endDate RFC3339String]
    }
  };
}
- (NSString*)schemaName {
  return @"body-weight";
}
@end

@interface OMHSerializerHeartRate : OMHSerializer; @end;
@implementation OMHSerializerHeartRate
+ (BOOL)canSerialize:(HKQuantitySample*)sample error:(NSError**)error {
  return YES;
}
- (id)bodyData {
  HKUnit* unit = [HKUnit unitFromString:@"count/min"];
  double value =
    [[(HKQuantitySample*)self.sample quantity] doubleValueForUnit:unit];
  return @{
    @"heart_rate": @{
      @"value": [NSNumber numberWithDouble:value],
      @"unit": @"beats/min"
    },
    @"effective_time_frame": @{
      @"date_time": [self.sample.startDate RFC3339String],
    }
  };
}
- (NSString*)schemaName {
  return @"heart-rate";
}
@end

@interface OMHSerializerBloodGlucose : OMHSerializer; @end;
@implementation OMHSerializerBloodGlucose
+ (BOOL)canSerialize:(HKQuantitySample*)sample error:(NSError**)error {
  return YES;
}
- (id)bodyData {
  NSString* unitString = @"mg/dL";
  HKUnit* unit = [HKUnit unitFromString:unitString];
  double value =
    [[(HKQuantitySample*)self.sample quantity] doubleValueForUnit:unit];
  return @{
    @"blood_glucose": @{
      @"value": [NSNumber numberWithDouble:value],
      @"unit": unitString
    },
    @"effective_time_frame": @{
      @"start_date_time": [self.sample.startDate RFC3339String],
      @"end_date_time": [self.sample.endDate RFC3339String]
    }
  };
}
- (NSString*)schemaName {
  return @"blood-glucose";
}
@end

@interface OMHSerializerEnergyBurned : OMHSerializer; @end;
@implementation OMHSerializerEnergyBurned
+ (BOOL)canSerialize:(HKQuantitySample*)sample error:(NSError**)error {
  return YES;
}
- (id)bodyData {
  NSString* unitString = @"kcal";
  HKUnit* unit = [HKUnit unitFromString:unitString];
  double value =
    [[(HKQuantitySample*)self.sample quantity] doubleValueForUnit:unit];
  return @{
    @"kcal_burned": @{
      @"value": [NSNumber numberWithDouble:value],
      @"unit": unitString
    },
    @"effective_time_frame": @{
      @"start_date_time": [self.sample.startDate RFC3339String],
      @"end_date_time": [self.sample.endDate RFC3339String]
    }
  };
}
- (NSString*)schemaName {
  return @"calories-burned";
}
@end

@interface OMHSerializerSleepAnalysis : OMHSerializer; @end;
@implementation OMHSerializerSleepAnalysis
+ (BOOL)canSerialize:(HKCategorySample*)sample error:(NSError**)error {
  if (sample.value == HKCategoryValueSleepAnalysisAsleep) return YES;
  if (error) {
    NSString* errorMessage =
      @"Unsupported HKCategoryValueSleepAnalysis value: HKCategoryValueSleepAnalysisInBed";
    NSDictionary* userInfo = @{ NSLocalizedDescriptionKey : errorMessage };
    *error = [NSError errorWithDomain: OMHErrorDomain
                                 code: OMHErrorCodeUnsupportedValues
                             userInfo: userInfo];
  }
  return NO;
}
- (id)bodyData {
  id value =
    [NSNumber numberWithFloat:
      [self.sample.endDate timeIntervalSinceDate:self.sample.startDate]];
  return @{
    @"sleep_duration": @{
      @"value": value,
      @"unit": @"sec"
    },
    @"effective_time_frame": @{
      @"start_date_time": [self.sample.startDate RFC3339String],
      @"end_date_time": [self.sample.endDate RFC3339String]
    }
  };
}
- (NSString*)schemaName {
  return @"sleep-duration";
}
@end

