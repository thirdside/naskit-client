require File.expand_path('../spec_helper.rb', __FILE__)

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
    before(:all) { subject.run }
    #after(:all) { FileUtils.rm_r(destination) }

    it "creates a destination tree" do
      File.exist?(destination).should be_true
      File.directory?(destination).should be_true
    end
  end
end