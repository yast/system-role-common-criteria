# ------------------------------------------------------------------------------
# Copyright (c) 2020 SUSE LLC
#
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of version 2 of the GNU General Public License as published by the
# Free Software Foundation.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# this program; if not, contact SUSE.
#
# To contact SUSE about this file by physical or electronic mail, you may find
# current contact information at www.suse.com.
# ------------------------------------------------------------------------------

module Yast
  class CCModuleClient < Client
    include Yast::I18n
    
    def initialize
      textdomain "cc"

      Yast.import "UI"
      Yast.import "Wizard"
      Yast.import "Directory"
      Yast.import "GetInstArgs"
      Yast.import "RichText"
      Yast.import "CustomDialogs"
      Yast.import "Language"

    end

    def main

      Wizard.CreateDialog

      display = UI.GetDisplayInfo
      space = display["TextMode"] ? 1 : 3

      # dialog caption
      caption = _("SUSE Linux Enterprise Common Criteria Evaluated Configuration")

      text = _("<p><b>Common Criteria Evaluated Configuration enabled</b></p>") +
        _(
          "<p>When installing SUSE Linux Enterprise in the Common Criteria evaluated configation," \
          "some restrictions apply to available configuration options.\n" \
          "Please refer to the deployment guide before proceeding.\n" \
          "Click <b>Next</b> to continue. </p>\n\n"
        )

      # help ttext
      help = _(
        "<p>Click <b>Next</b> to continue.</p>\n"
      )

      if Builtins.regexpmatch(text, "</.*>")
        rt = RichText(Id(:text), text)
      else
        Builtins.y2debug("plain text")
        rt = RichText(Id(:text), Opt(:plainText), text)
      end

      contents = VBox(
        VSpacing(space),
        HBox(
          HSpacing(2 * space),
          rt,
          HSpacing(2 * space)
        ),
        VSpacing(2)
      )

      entropy = SCR.Read(path(".target.string"), "/proc/sys/kernel/random/entropy_avail").to_s
      y2milestone("entropy %1", entropy)

      Wizard.SetContents(
        caption,
        contents,
        help,
        GetInstArgs.enable_back,
        GetInstArgs.enable_next
      )
      Wizard.SetFocusToNextButton

      ret = nil
      loop do
        ret = UI.UserInput

        break if ret != :abort
        break if Popup.ReallyAbort(:painless)
      end

      if ret == :next
        # for testing to speed things up
        #Yast::Pkg.SetSolverFlags("onlyRequires" => true)

        # put libgcrypt into FIPS mode. libstorage-ng calls the cryptsetup
        # external command so this takes effect when formatting luks volumes.
        # Needs to happen in instsys. The target system boots with fips=1 kernel
        # command line so this setting is not needed.
        WFM.Execute(path(".local.mkdir"), "/etc/gcrypt")
        WFM.Write(path(".local.string"), "/etc/gcrypt/fips_enabled", "1")
      end

      Wizard.CloseDialog
      ret
    end
  end
end

Yast::CCModuleClient.new.main
