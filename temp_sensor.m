//
//  main.m
//  sensors
//
//  Created by Yang on 11/26/20.
//


#include <IOKit/hidsystem/IOHIDEventSystemClient.h>
#include <Foundation/Foundation.h>
#include <stdio.h>

// Declarations from other IOKit source code

typedef struct __IOHIDEvent *IOHIDEventRef;
typedef struct __IOHIDServiceClient *IOHIDServiceClientRef;
#ifdef __LP64__
typedef double IOHIDFloat;
#else
typedef float IOHIDFloat;
#endif

IOHIDEventSystemClientRef IOHIDEventSystemClientCreate(CFAllocatorRef allocator);
int IOHIDEventSystemClientSetMatching(IOHIDEventSystemClientRef client, CFDictionaryRef match);
int IOHIDEventSystemClientSetMatchingMultiple(IOHIDEventSystemClientRef client, CFArrayRef match);
IOHIDEventRef IOHIDServiceClientCopyEvent(IOHIDServiceClientRef, int64_t , int32_t, int64_t);
CFStringRef IOHIDServiceClientCopyProperty(IOHIDServiceClientRef service, CFStringRef property);
IOHIDFloat IOHIDEventGetFloatValue(IOHIDEventRef event, int32_t field);

CFDictionaryRef matching(int page, int usage)
{
    CFNumberRef nums[2];
    CFStringRef keys[2];
    
    keys[0] = CFStringCreateWithCString(0, "PrimaryUsagePage", 0);
    keys[1] = CFStringCreateWithCString(0, "PrimaryUsage", 0);
    nums[0] = CFNumberCreate(0, kCFNumberSInt32Type, &page);
    nums[1] = CFNumberCreate(0, kCFNumberSInt32Type, &usage);
    
    CFDictionaryRef dict = CFDictionaryCreate(0, (const void**)keys, (const void**)nums, 2, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    return dict;
}

CFArrayRef getProductNames(CFDictionaryRef sensors) {
    IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault); // in CFBase.h = NULL
    // ... this is the same as using kCFAllocatorDefault or the return value from CFAllocatorGetDefault()
    IOHIDEventSystemClientSetMatching(system, sensors);
    CFArrayRef matchingsrvs = IOHIDEventSystemClientCopyServices(system); // matchingsrvs = matching services
    
    long count = CFArrayGetCount(matchingsrvs);
    CFMutableArrayRef array = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    
    for (int i = 0; i < count; i++) {
        IOHIDServiceClientRef sc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(matchingsrvs, i);
        CFStringRef name = IOHIDServiceClientCopyProperty(sc, CFSTR("Product")); // here we use ...CopyProperty
        if (name) {
            CFArrayAppendValue(array, name);
        } else {
            CFArrayAppendValue(array, @"noname"); // @ gives a Ref like in "CFStringRef name"
        }
    }
    return array;
}

// from IOHIDFamily/IOHIDEventTypes.h
// e.g., https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-701.60.2/IOHIDFamily/IOHIDEventTypes.h.auto.html

#define IOHIDEventFieldBase(type)   (type << 16)
#define kIOHIDEventTypeTemperature  15
#define kIOHIDEventTypePower        25

CFArrayRef getPowerValues(CFDictionaryRef sensors) {
    IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientSetMatching(system, sensors);
    CFArrayRef matchingsrvs = IOHIDEventSystemClientCopyServices(system);
    
    long count = CFArrayGetCount(matchingsrvs);
    CFMutableArrayRef array = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    for (int i = 0; i < count; i++) {
        IOHIDServiceClientRef sc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(matchingsrvs, i);
        IOHIDEventRef event = IOHIDServiceClientCopyEvent(sc, kIOHIDEventTypePower, 0, 0);
        
        CFNumberRef value;
        if (event != 0) {
            double temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypePower));
            value = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &temp);
        } else {
            double temp = 0;
            value = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &temp);
        }
        CFArrayAppendValue(array, value);
    }
    return array;
}

CFArrayRef getThermalValues(CFDictionaryRef sensors) {
    IOHIDEventSystemClientRef system = IOHIDEventSystemClientCreate(kCFAllocatorDefault);
    IOHIDEventSystemClientSetMatching(system, sensors);
    CFArrayRef matchingsrvs = IOHIDEventSystemClientCopyServices(system);
    
    long count = CFArrayGetCount(matchingsrvs);
    CFMutableArrayRef array = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
    
    for (int i = 0; i < count; i++) {
        IOHIDServiceClientRef sc = (IOHIDServiceClientRef)CFArrayGetValueAtIndex(matchingsrvs, i);
        IOHIDEventRef event = IOHIDServiceClientCopyEvent(sc, kIOHIDEventTypeTemperature, 0, 0); // here we use ...CopyEvent
        
        CFNumberRef value;
        if (event != 0) {
            double temp = IOHIDEventGetFloatValue(event, IOHIDEventFieldBase(kIOHIDEventTypeTemperature));
            value = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &temp);
        } else {
            double temp = 0;
            value = CFNumberCreate(kCFAllocatorDefault, kCFNumberDoubleType, &temp);
        }
        CFArrayAppendValue(array, value);
    }
    return array;
}

void dumpValues(CFArrayRef values)
{
    long count = CFArrayGetCount(values);
    for (int i = 0; i < count; i++) {
        CFNumberRef value = CFArrayGetValueAtIndex(values, i);
        double temp = 0.0;
        CFNumberGetValue(value, kCFNumberDoubleType, &temp);
        // NSLog(@"value = %lf\n", temp);
        printf("%0.1lf, ", temp);
    }
}

void dumpNames(CFArrayRef names, char *cat)
{
    long count = CFArrayGetCount(names);
    for (int i = 0; i < count; i++) {
        NSString *name = (NSString *)CFArrayGetValueAtIndex(names, i);
        // NSLog(@"value = %lf\n", temp);
        // printf("%s (%s), ", [name UTF8String], cat);
        printf("%s, ", [name UTF8String]);
    }
}

NSArray* currentArray() {
    CFDictionaryRef currentSensors = matching(0xff08, 2);
    return CFBridgingRelease(getProductNames(currentSensors));
}

NSArray* voltageArray() {
    CFDictionaryRef currentSensors = matching(0xff08, 3);
    return CFBridgingRelease(getProductNames(currentSensors));
}

NSArray* thermalArray() {
    CFDictionaryRef currentSensors = matching(0xff00, 5);
    return CFBridgingRelease(getProductNames(currentSensors));
}

NSArray* returnCurrentValues() {
    CFDictionaryRef currentSensors = matching(0xff08, 2);
    return CFBridgingRelease(getPowerValues(currentSensors));
}

NSArray* returnVoltageValues() {
    CFDictionaryRef voltageSensors = matching(0xff08, 3);
    return CFBridgingRelease(getPowerValues(voltageSensors));
}

NSArray* returnThermalValues() {
    CFDictionaryRef currentSensors = matching(0xff00, 5);
    return CFBridgingRelease(getThermalValues(currentSensors));
}


//extern uint64_t my_mhz(void);
//extern void mybat(void);

#if 1
int main () {
    //  Primary Usage Page:
    //    kHIDPage_AppleVendor                        = 0xff00,
    //    kHIDPage_AppleVendorTemperatureSensor       = 0xff05,
    //    kHIDPage_AppleVendorPowerSensor             = 0xff08,
    //
    //  Primary Usage:
    //    kHIDUsage_AppleVendor_TemperatureSensor     = 0x0005,
    //    kHIDUsage_AppleVendorPowerSensor_Current    = 0x0002,
    //    kHIDUsage_AppleVendorPowerSensor_Voltage    = 0x0003,
    // See IOHIDFamily/AppleHIDUsageTables.h for more information
    // https://opensource.apple.com/source/IOHIDFamily/IOHIDFamily-701.60.2/IOHIDFamily/AppleHIDUsageTables.h.auto.html
    
    CFDictionaryRef currentSensors = matching(0xff08, 2);
    CFDictionaryRef voltageSensors = matching(0xff08, 3);
    CFDictionaryRef thermalSensors = matching(0xff00, 5); // 65280_10 = FF00_16
    // I change it to 0xff00, due to ioreg -dlx
    
    CFArrayRef currentNames = getProductNames(currentSensors);
    CFArrayRef voltageNames = getProductNames(voltageSensors);
    CFArrayRef thermalNames = getProductNames(thermalSensors);
    
    
//  printf("freq, v_bat, a_bat, temp_bat");
//    dumpNames(voltageNames, "V");
//    dumpNames(currentNames, "A");
    dumpNames(thermalNames, "C");
    printf("\n"); fflush(stdout);
    
    while (1) {
        CFArrayRef currentValues = getPowerValues(currentSensors);
        CFArrayRef voltageValues = getPowerValues(voltageSensors);
        CFArrayRef thermalValues = getThermalValues(thermalSensors);
//        printf("%lld, ", my_mhz());
//        mybat();
        
//        dumpValues(voltageValues);
//        dumpValues(currentValues);
        dumpValues(thermalValues);
        printf("\n"); fflush(stdout);
        usleep(1000000); // usleep - suspend execution for microsecond intervals
        CFRelease(currentValues);
        CFRelease(voltageValues);
        CFRelease(thermalValues);
    }
    
#if 0
    NSLog(@"%@\n", CFArrayGetValueAtIndex(currentNames, 0));
    NSLog(@"%@\n", CFArrayGetValueAtIndex(currentNames, 1));
    NSLog(@"%@\n", CFArrayGetValueAtIndex(voltageNames, 0));
    NSLog(@"%@\n", CFArrayGetValueAtIndex(voltageNames, 1));
    NSLog(@"%@\n", CFArrayGetValueAtIndex(thermalNames, 0));
    NSLog(@"%@\n", CFArrayGetValueAtIndex(thermalNames, 1));
#endif
    
    // IOHIDEventRef event = IOHIDServiceClientCopyEvent(alssc, 25, 0, 0);
    
    return 0;
}
#endif
