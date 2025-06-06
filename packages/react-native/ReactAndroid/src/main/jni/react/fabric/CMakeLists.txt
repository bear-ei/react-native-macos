# Copyright (c) Meta Platforms, Inc. and affiliates.
#
# This source code is licensed under the MIT license found in the
# LICENSE file in the root directory of this source tree.

cmake_minimum_required(VERSION 3.13)

include(${REACT_ANDROID_DIR}/src/main/jni/first-party/jni-lib-merge/SoMerging-utils.cmake)

file(GLOB fabricjni_SRCS CONFIGURE_DEPENDS *.cpp)

add_library(
        fabricjni
        OBJECT
        ${fabricjni_SRCS}
)

target_include_directories(fabricjni PUBLIC ${CMAKE_CURRENT_SOURCE_DIR})

target_merge_so(fabricjni)

target_link_libraries(
        fabricjni
        fbjni
        folly_runtime
        glog
        jsi
        mapbufferjni
        react_codegen_rncore
        react_debug
        react_featureflags
        react_render_animations
        react_render_attributedstring
        react_render_componentregistry
        react_render_core
        react_render_debug
        react_render_dom
        react_render_graphics
        react_render_imagemanager
        react_render_mapbuffer
        react_render_mounting
        react_render_runtimescheduler
        react_render_scheduler
        react_render_telemetry
        react_render_textlayoutmanager
        react_render_uimanager
        react_render_uimanager_consistency
        rrc_legacyviewmanagerinterop
        react_utils
        reactnativejni
        rrc_image
        rrc_modal
        rrc_progressbar
        rrc_root
        rrc_safeareaview
        rrc_scrollview
        rrc_switch
        rrc_text
        rrc_textinput
        rrc_unimplementedview
        rrc_view
        yoga
)

target_compile_options(
        fabricjni
        PRIVATE
        -DLOG_TAG=\"Fabric\"
        -fexceptions
        -frtti
        -std=c++20
        -Wall
)
