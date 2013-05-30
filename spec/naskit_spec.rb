require File.expand_path('../spec_helper.rb', __FILE__)
require 'digest'

describe Naskit::API::AtomicParsley do
  describe ".get" do
    let(:file) { File.expand_path('../assets/empty.m4v', __FILE__) }
    subject { Naskit::API::AtomicParsley.get(file) }

    it { should be_a(Naskit::Episode) }

    its(:title)       { should == "Empty" }
    its(:season)      { should == "1" }
    its(:number)      { should == "1" }
    its(:show)        { should == "Empty videos" }
    its(:description) { should == "An empty video"}
  end
end

# This test requires Naskit to be running
describe Naskit::API::WWW do
  describe ".get" do
    let(:file) { File.expand_path('../assets/How.I.Met.Your.Mother.S01E01.mpeg', __FILE__) }
    subject { Naskit::API::WWW.get(file) }

    it { should be_a(Naskit::Episode) }
  end
end

describe Naskit::App do
  describe "source and destination" do
    source = File.expand_path("../assets", __FILE__)
    destination = File.expand_path("../result-assets", __FILE__)

    subject {
      Naskit::App.new :source       => source,
                      :destination  => destination,
                      :convert      => true,
                      :extensions   => Naskit::DEFAULT_EXTENSIONS + ["mpeg"],
                      :format       => Naskit::DEFAULT_FORMAT
    }

    its(:files) { should have(2).members }


    context "#run" do
      before { subject.run }
      after { FileUtils.rm_r(destination) }

      it "creates a destination tree" do
        File.exist?(destination).should be_true
        File.directory?(destination).should be_true
      end

      it "copies the video if it doesn't need to transcode" do
        source_file = File.join(source, "empty.m4v")
        destination_file = File.join(destination, "Empty videos/1/1. Empty.m4v")
        Digest::MD5.file(source_file).hexdigest.should == Digest::MD5.file(destination_file).hexdigest
      end

      it "transcode the mpeg" do
        source_file = File.join(source, "How.I.Met.Your.Mother.S01E01.mpeg")
        destination_file = File.join(destination, "How I Met Your Mother/1/1. Pilot.m4v")
        File.exist?(destination_file).should be_true
        Digest::MD5.file(source_file).hexdigest.should_not == Digest::MD5.file(destination_file).hexdigest
      end
    end
  end

  describe "--find-missing" do

  end
end

describe Naskit::Converter::M4V do
  context "not matching" do
    subject { Naskit::Converter::M4V.new("titi.mpeg", "toto")}

    its(:match?) { should be_false }
    its(:command) { should == "avconv -i titi.mpeg -c:a copy -c:v libx264 toto.m4v" }
  end

  context "matching" do
    source = File.expand_path("../assets", __FILE__)

    let(:source_file) { File.join(source, "empty.m4v") }
    subject { Naskit::Converter::M4V.new(source_file, "toto") }

    its(:match?) { should be_true }
    its(:command) { should == "avconv -i #{Shellwords.escape(source_file)} -c:a copy -c:v copy toto.m4v" }
  end
end