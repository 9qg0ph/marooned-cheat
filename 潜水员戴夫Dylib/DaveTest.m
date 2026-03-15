// DaveTest.m - Minimal test dylib: ONLY logs, no UI, no hooks
// If this crashes, the problem is NOT our code but the injection environment
#import <Foundation/Foundation.h>

__attribute__((constructor))
static void DaveTestInit(void) {
    NSLog(@"[DaveTest] ===== MINIMAL TEST DYLIB LOADED =====");
    NSLog(@"[DaveTest] If you see this but game crashes, the crash is from another dylib or game protection.");
    NSLog(@"[DaveTest] This dylib does NOTHING else.");
}
