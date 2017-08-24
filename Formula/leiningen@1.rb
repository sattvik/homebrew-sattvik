class LeiningenAT1 < Formula
  desc "Build tool for Clojure"
  homepage "https://github.com/technomancy/leiningen"
  url "https://github.com/technomancy/leiningen/archive/1.7.1.tar.gz"
  sha256 "6996549fb6d99c28d26ab836a1343395ba09ebcd2801905f288bbe5510f84db7"
  head "https://github.com/technomancy/leiningen.git"

  resource "jar" do
    url "https://github.com/downloads/technomancy/leiningen/leiningen-1.7.1-standalone.jar"
    sha256 "5d167b7572b9652d44c2b58a13829704842d976fd2236530ef552194e6c12150"
  end

  def install
    jar = "leiningen-#{version}-standalone.jar"
    resource("jar").stage do
      libexec.install "leiningen-#{version}-standalone.jar" => jar
    end

    # bin/lein autoinstalls and autoupdates, which doesn't work too well for us
    inreplace "bin/lein-pkg" do |s|
      s.gsub! /\/usr\/share\/java\/leiningen-\$LEIN_VERSION\.jar/, libexec/jar
      s.gsub! /-Xbootclasspath\/a:"\$CLOJURE_JAR"/, ""
      s.gsub! /\$SHARE_JARS/, "\"\""
      s.gsub! /-r -m -q/, "-r -m dummy -q"
    end

    bin.install "bin/lein-pkg" => "lein1"

    inreplace "bash_completion.bash", /lein/, "lein1"
    bash_completion.install "bash_completion.bash" => "lein1-completion.bash"
    inreplace "zsh_completion.zsh", /lein/, "lein1"
    zsh_completion.install "zsh_completion.zsh" => "_lein1"
  end

  def caveats; <<-EOS.undent
    Dependencies will be installed to:
      $HOME/.m2/repository
    To play around with Clojure run `lein1 repl` or `lein1 help`.
    EOS
  end

  test do
    ENV.java_cache

    (testpath/"project.clj").write <<-EOS.undent
      (defproject brew-test "1.0"
        :dependencies [[org.clojure/clojure "1.5.1"]])
    EOS
    (testpath/"src/brew_test/core.clj").write <<-EOS.undent
      (ns brew-test.core)
      (defn adds-two
        "I add two to a number"
        [x]
        (+ x 2))
    EOS
    (testpath/"test/brew_test/core_test.clj").write <<-EOS.undent
      (ns brew-test.core-test
        (:require [clojure.test :refer :all]
                  [brew-test.core :as t]))
      (deftest canary-test
        (testing "adds-two yields 4 for input of 2"
          (is (= 4 (t/adds-two 2)))))
    EOS
    system "#{bin}/lein1", "test"
  end
end
