# minio-mc: Build a bottle for Linuxbrew
class MinioMc < Formula
  desc "Replacement for ls, cp and other commands for object storage"
  homepage "https://github.com/minio/mc"
  url "https://github.com/minio/mc.git",
      :tag      => "RELEASE.2019-10-02T19-41-02Z",
      :revision => "26b9044a8676a8c5ff79a6054343e5be74c35135"
  version "20191002194102"

  bottle do
    cellar :any_skip_relocation
    sha256 "0b81d4b1f5f97dce43fb77117a98ac7f10adc82146ed1b29dc657770366ab21d" => :catalina
    sha256 "3a85394b3ca31a22fc3a897ff376d8a88fcfffaf0be8b2af66f1bc68914a9cd9" => :mojave
    sha256 "f52d51b974009d99558a49490b0de689abd137eea2aa816bc4f285b4806a4640" => :high_sierra
  end

  depends_on "go" => :build

  conflicts_with "midnight-commander", :because => "Both install a `mc` binary"

  def install
    ENV["GOPATH"] = buildpath
    src = buildpath/"src/github.com/minio/mc"
    src.install buildpath.children
    src.cd do
      if build.head?
        system "go", "build", "-o", buildpath/"mc"
      else
        minio_release = `git tag --points-at HEAD`.chomp
        minio_version = minio_release.gsub(/RELEASE\./, "").chomp.gsub(/T(\d+)\-(\d+)\-(\d+)Z/, 'T\1:\2:\3Z')
        minio_commit = `git rev-parse HEAD`.chomp
        proj = "github.com/minio/mc"

        system "go", "build", "-o", buildpath/"mc", "-ldflags", <<~EOS
          -X #{proj}/cmd.Version=#{minio_version}
          -X #{proj}/cmd.ReleaseTag=#{minio_release}
          -X #{proj}/cmd.CommitID=#{minio_commit}
        EOS
      end
    end

    bin.install buildpath/"mc"
    prefix.install_metafiles
  end

  test do
    system bin/"mc", "mb", testpath/"test"
    assert_predicate testpath/"test", :exist?
  end
end
