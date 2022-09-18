class DovecotDev < Formula
  desc "IMAP/POP3 server"
  homepage "http://dovecot.org/"
  url "https://dovecot.org/releases/2.3/dovecot-2.3.19.1.tar.gz"
  version "2.3.19.1"
  sha256 "db5abcd87d7309659ea6b45b2cb6ee9c5f97486b2b719a5dd05a759e1f6a5c51"
  license all_of: ["BSD-3-Clause", "LGPL-2.1-or-later", "MIT", "Unicode-DFS-2016", :public_domain]

  depends_on "pkg-config" => :build
  depends_on "openssl@1.1"
  depends_on "clucene"
  depends_on "cmake"
  depends_on "icu4c"
  depends_on "libstemmer-dev"
  depends_on "solr"

  uses_from_macos "bzip2"
  uses_from_macos "sqlite"

  ###############################################################################
  # this is for flatcurve #
  ###############################################################################
  # depends_on "xapian"
  # depends_on "libexttextcat"
  # depends_on "automake"
  # depends_on "libtool"

  # resource "flatcurve" do
  #   url "https://github.com/slusarz/dovecot-fts-flatcurve/archive/refs/heads/master.zip"
  #   sha256 "373cb90cf1c091e30dcc8611e11f4b2997e721f38198f5f16c743178b0c44655"
  #   # url "https://github.com/slusarz/dovecot-fts-flatcurve/archive/refs/tags/v0.1.0.zip"
  #   # sha256 "f6ba04d80df035346e15a51f2a0a3bdb83f23b7a1e7494fd1b6071a9b09ce549"
  # end

  resource "pigeonhole" do
    url "https://pigeonhole.dovecot.org/releases/2.3/dovecot-2.3-pigeonhole-0.5.19.tar.gz"
    sha256 "637709a83fb1338c918e5398049f96b7aeb5ae00696794ed1e5a4d4c0ca3f688"

    # Fix -flat_namespace being used on Big Sur and later.
    patch do
      url "https://raw.githubusercontent.com/kour1er/homebrew-repo/main/Patches/dovecot_patch.diff"
      sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
    end
  end

  resource "xaps" do
    url "https://github.com/st3fan/dovecot-xaps-plugin/archive/v0.8.tar.gz"
    sha256 "315eb0a7507c94884f636fe348f8ac576916325225fd644fc3e43fa5c28f6433"
  end

  # Fix -flat_namespace being used on Big Sur and later.
  patch do
    url "https://raw.githubusercontent.com/kour1er/homebrew-repo/main/Patches/dovecot_patch.diff"
    sha256 "35acd6aebc19843f1a2b3a63e880baceb0f5278ab1ace661e57a502d9d78c93c"
  end

  def install
    args = %W[
      --prefix=#{prefix}
      --libexecdir=#{libexec}
      --sysconfdir=#{etc}
      --localstatedir=#{var}
      --disable-dependency-tracking
      --with-pam
      --with-sqlite
      --with-bzlib
      --with-zlib
      --with-ssl=openssl
      --with-icu
      --with-lucene
      --with-stemmer
      --with-solr
    ]

    system "./configure", *args
    system "make", "install"

    ####################
    # Pigeonhole plugin
    ####################
    resource("pigeonhole").stage do
      args = %W[
        --disable-dependency-tracking
        --with-dovecot=#{lib}/dovecot
        --prefix=#{prefix}
      ]

      system "./configure", *args
      system "make"
      system "make", "install"
    end

    ################################
    # XAPS push notification plugin
    ################################
    resource("xaps").stage do
      inreplace "CMakeLists.txt" do |s|
        s.sub! "include_directories(/usr/local/include/dovecot)", "include_directories(${DOVECOTINC})"
        s.sub! "find_library(LIBDOVECOT dovecot /usr/lib/dovecot/ /usr/local/lib/dovecot/)", "find_library(LIBDOVECOT dovecot /usr/lib/dovecot/ ${DOVECOTLIB})"
        s.sub! "find_library(LIBDOVECOTSTORAGE dovecot-storage /usr/lib/dovecot/ /usr/local/lib/dovecot/)", "find_library(LIBDOVECOTSTORAGE dovecot-storage /usr/lib/dovecot/ ${DOVECOTLIB})"
        s.sub! "/usr/lib/dovecot/modules", "${DOVECOTLIB}"
        s.sub! "/usr/lib/dovecot/modules", "${DOVECOTLIB}"
      end

      args = %W[
        -DCMAKE_BUILD_TYPE=Release
        -DDOVECOTLIB=#{lib}/dovecot
        -DDOVECOTINC=#{include}/dovecot
      ]

      mkdir "build"
      cd "build"
      system "cmake", "..", *std_cmake_args, *args
      system "make", "install"
    end

  #######################
  # Flatcurve FTS plugin
  #######################
#     resource("flatcurve").stage do
#     ENV.append_to_cflags "-std=gnu++11"
#     ENV["CXXFLAGS"] = '-std=gnu++0x'
#
#       args = %W[
#         --with-dovecot=#{lib}/dovecot
#         --prefix=#{prefix}/dovecot
#       ]
#
#       system "./autogen.sh"
#       system "./configure", *args
#       system "make", "install"
#     end
  #######################
  # END of plugins
  #######################
  end

  def post_install
    (var/"log/dovecot").mkpath
  end

  plist_options startup: true
  def plist
    <<~EOS
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
        <dict>
          <key>Label</key>
          <string>#{plist_name}</string>
          <key>KeepAlive</key>
          <false/>
          <key>RunAtLoad</key>
          <true/>
          <key>ProgramArguments</key>
          <array>
            <string>#{opt_sbin}/dovecot</string>
            <string>-F</string>
          </array>
          <key>StandardErrorPath</key>
          <string>#{var}/log/dovecot/dovecot.log</string>
          <key>StandardOutPath</key>
          <string>#{var}/log/dovecot/dovecot.log</string>
          <key>SoftResourceLimits</key>
          <dict>
          <key>NumberOfFiles</key>
          <integer>1000</integer>
          </dict>
          <key>HardResourceLimits</key>
          <dict>
          <key>NumberOfFiles</key>
          <integer>1024</integer>
          </dict>
        </dict>
      </plist>
    EOS
  end

end
