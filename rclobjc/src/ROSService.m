/* Copyright 2016 Esteve Fernandez <esteve@apache.org>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include "rcl/error_handling.h"
#include "rcl/node.h"
#include "rcl/rcl.h"
#include "rmw/rmw.h"

#import "rclobjc/ROSService.h"

@interface ROSService ()

@property(assign) intptr_t nodeHandle;
@property(assign) intptr_t serviceHandle;
@property(assign) Class serviceType;
@property(assign) NSString *serviceName;
@property(assign) void (*callback)(NSObject *, NSObject *, NSObject *);

@end

@implementation ROSService

@synthesize nodeHandle;
@synthesize serviceHandle;
@synthesize serviceType;
@synthesize serviceName;
@synthesize callback;


- (void)dispose{
  intptr_t node_handle = self.nodeHandle;
  intptr_t service_handle = self.serviceHandle;

  if (service_handle == 0) {
    // everything is ok, already destroyed
    return;
  }

  if (node_handle == 0) {
    // TODO(esteve): handle this, node is null, but service isn't
    return;
  }

  rcl_node_t * node = (rcl_node_t *)node_handle;

  assert(node != NULL);

  rcl_service_t * service = (rcl_service_t *)service_handle;

  assert(service != NULL);

  rcl_ret_t ret = rcl_service_fini(service, node);

  if (ret != RCL_RET_OK) {
    NSLog(@"Failed to destroy service: %s", rcl_get_error_string_safe());
    rcl_reset_error();
  }

  self.nodeHandle = 0;
}

- (instancetype)initWithArguments:(intptr_t)
                       nodeHandle:(intptr_t)
                    serviceHandle:(Class)
                      serviceType:(NSString *)
                      serviceName:(void (*)(NSObject *, NSObject *,
                                            NSObject *))callback {
  self.nodeHandle = nodeHandle;
  self.serviceHandle = serviceHandle;
  self.serviceType = serviceType;
  self.serviceName = serviceName;
  self.callback = callback;
  return self;
}
@end
