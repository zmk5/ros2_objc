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

#import "rclobjc/ROSPublisher.h"

@interface ROSPublisher ()

@property(assign) intptr_t nodeHandle;
@property(assign) intptr_t publisherHandle;
@property(assign) NSString *topic;

@end

@implementation ROSPublisher

@synthesize nodeHandle;
@synthesize publisherHandle;
@synthesize topic;

- (void)publish:(id)message {
  rcl_publisher_t *publisher = (rcl_publisher_t *)self.publisherHandle;

  // TODO(esteve): move messageType as a property
  // intptr_t converter_ptr = [[message class]
  // performSelector:@selector(fromObjcConverterPtr)];
  intptr_t converter_ptr = [[message class] fromObjcConverterPtr];

  typedef void *(*convert_from_objc_signature)(void *);
  convert_from_objc_signature convert_from_objc =
      (convert_from_objc_signature)converter_ptr;

  void *raw_ros_message = convert_from_objc(message);

  // TODO(zmk5): Figure out how to get rmw_publisher_allocation_t as third param
  rcl_ret_t ret = rcl_publish(publisher, raw_ros_message, NULL);

  if (ret != RCL_RET_OK) {
    // TODO(esteve): handle error
  }

  intptr_t destroy_msg_ptr = [[message class] destroyMsgPtr];

   typedef void (*destroy_msg_signature)(void *);
   destroy_msg_signature destroy_msg =
       (destroy_msg_signature)destroy_msg_ptr;

   destroy_msg(raw_ros_message);

}

- (void)dispose{

  intptr_t node_handle = self.nodeHandle;
  intptr_t publisher_handle = self.publisherHandle;

  if (publisher_handle == 0) {
    // everything is ok, already destroyed
    return;
  }

  if (node_handle == 0) {
    // TODO(esteve): handle this, node is null, but publisher isn't
    return;
  }

  rcl_node_t * node = (rcl_node_t *)node_handle;

  rcl_publisher_t * publisher = (rcl_publisher_t *)publisher_handle;

  assert(publisher != NULL);

  rcl_ret_t ret = rcl_publisher_fini(publisher, node);

  if (ret != RCL_RET_OK) {
    NSLog(@"Failed to destroy publisher: %s", rcl_get_error_string_safe());
    rcl_reset_error();
  }

  self.nodeHandle = 0;
}

- (instancetype)initWithArguments:(intptr_t)
                       nodeHandle:(intptr_t)
                  publisherHandle:(NSString *)topic {
  self.nodeHandle = nodeHandle;
  self.publisherHandle = publisherHandle;
  self.topic = topic;
  return self;
}


@end
