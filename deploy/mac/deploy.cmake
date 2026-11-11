# SPDX-FileCopyrightText: (C) 2024 Chris Rizzitello <sithlord48@gmail.com>
# SPDX-License-Identifier: MIT

# HACK This is set when the files is included so its the real path
# calling CMAKE_CURRENT_LIST_DIR after include would return the wrong scope var
set(MY_DIR ${CMAKE_CURRENT_LIST_DIR})
set(OSX_BUNDLE ${BUILD_OSX_BUNDLE})

set(OS_STRING "macos-${BUILD_ARCHITECTURE}")

if (OSX_BUNDLE)
  set(_codesign_identity "-")
  if (APPLE_CODESIGN_DEV)
    set(_codesign_identity "${APPLE_CODESIGN_DEV}")
  endif()
  # Personal release signing is separate from development signing: it must not
  # enable the debugger/JIT entitlements from entitlements-dev.plist.
  set(MAC_INPUT_CODESIGN_IDENTITY "" CACHE STRING "Persistent identity for personal macOS input-fix packages")
  set(_timestamp_arg "-timestamp")
  if(MAC_INPUT_CODESIGN_IDENTITY)
    set(_codesign_identity "${MAC_INPUT_CODESIGN_IDENTITY}")
    set(_timestamp_arg "")
  endif()
  install(CODE "execute_process(COMMAND
    ${DEPLOYQT}
    \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_PROJECT_PROPER_NAME}.app\"
    -hardened-runtime ${_timestamp_arg} \"-codesign=${_codesign_identity}\"
    COMMAND_ERROR_IS_FATAL ANY
  )")
  if(MAC_INPUT_CODESIGN_IDENTITY)
    install(CODE "execute_process(COMMAND /bin/bash
      \"${MY_DIR}/sign-input-build.sh\"
      \"\${CMAKE_INSTALL_PREFIX}/${CMAKE_PROJECT_PROPER_NAME}.app\"
      \"${MAC_INPUT_CODESIGN_IDENTITY}\"
      \"${MY_DIR}/input-build-signing.cer\"
      COMMAND_ERROR_IS_FATAL ANY
    )")
  endif()
  set(CPACK_PACKAGE_ICON "${MY_DIR}/dmg-volume.icns")
  set(CPACK_DMG_BACKGROUND_IMAGE "${MY_DIR}/dmg-background.tiff")
  set(CPACK_DMG_DS_STORE_SETUP_SCRIPT "${MY_DIR}/generate_ds_store.applescript")
  set(CPACK_DMG_VOLUME_NAME "${CMAKE_PROJECT_PROPER_NAME}")
  set(CPACK_DMG_SLA_USE_RESOURCE_FILE_LICENSE ON)
  set(CPACK_GENERATOR "DragNDrop")
endif()
