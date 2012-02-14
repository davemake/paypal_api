require "spec_helper"

describe Paypal::Api do
	before do
		@api = Paypal::Api
	end

	describe :set_request_signature do
		it "should be callable from a class body definition" do
			expect {
				class Test < @api
					set_request_signature :test, {}
				end
			}.to_not raise_exception
		end

		context "with field descriptions" do
			before do
				class Test < @api
					set_request_signature :tester, {
						:test_field => "something",
						:optional => @api::Optional.new(String),
						:string => String,
						:fixnum => Fixnum,
						:default => @api::Default.new("tamp", Fixnum),
						:enum => @api::Enum.new("one", "two"),
						:sequential => @api::Sequential.new({:l_string => String, :l_fixnum => Fixnum, :l_set_category => Optional.new(String)})
					}
				end
			end

			it "should add getters for all keys" do
				Test.tester.payload.each do |k,v|
					Test.tester.respond_to?(k).should be_true
				end
			end

			it "should return a dynamic request object" do
				Test.tester.class.should eq(Paypal::TesterRequest)
			end

			it "should make the class respond to class method" do
				Test.respond_to?(:tester).should be_true
			end

			it "should add constant getters and not setters for value types" do
				Test.tester.respond_to?(:test_field).should be_true
				Test.tester.send(:test_field).should eq("something")
				Test.tester.respond_to?(:test_field=).should be_false
			end

			it "should add setters for all non-constant types" do
				request = Test.tester
				request.payload.each do |k,v|
					if [String, Fixnum, Float].include?(v.class)
						request.respond_to?(k).should be_false
					else
						request.respond_to?(k).should be_true
					end
				end
			end

			it "should raise an InvalidRequest error when missing required fields" do
				request = Test.tester
				expect {
					request.make
				}.to raise_exception(Paypal::InvalidRequest)
			end

			describe "setters" do
				before do
					@request = Test.tester
				end

				it "should handle sequential types" do
					@request.sequential.push({:l_string => "sasdf", :l_fixnum => 23, :l_set_category => "asdfasdf"})

					@request.sequentials_string.should include("sasdf")
					@request.sequentials_string.should include("23")

					@request.sequential.push({:l_string => "alf", :l_fixnum => 22})
					@request.sequentials_string.should include("L_FIXNUM1")
					@request.sequentials_string.should include("L_SETCATEGORY0")
					@request.sequentials_string.should_not include("L_SETCATEGORY1")

					expect {
						@request.sequential.push({:l_string => "sass"})
					}.to raise_exception Paypal::InvalidParameter

					expect {
						@request.sequential.push({:l_string => "sass", :l_fixnum => "string"})
					}.to raise_exception Paypal::InvalidParameter
				end

				it "should handle types like String Fixnum and Float" do
					@request.string = "a string"
					@request.string.should eq("a string")

					expect {
						@request.string = 10
					}.to raise_exception Paypal::InvalidParameter
				end

				it "should handle types of Parameters" do
					@request.payload.each do |k, v|
						@request.respond_to?("#{k}=").should be_true if v.class < @api::Parameter
					end

					@request.enum = "one"
					@request.enum.should eq("one")
				end

				it "should handle constant types" do
					@request.test_field.should eq("something")
					@request.respond_to?(:test_field=).should be_false
				end

				it "should handle default types" do
					@request.default.should eq("tamp")
					@request.default = 10
					@request.default.should eq(10)

					expect {
						@request.default = "asdf"
					}.to raise_exception Paypal::InvalidParameter
				end
			end

		end

	end

	describe Paypal::Api::Parameter do

		describe Paypal::Api::Enum do
			it "should only allow enumberated input" do
				param = @api::Enum.new("first", "second", "third")

				param.parse("first").should eq("first")
				param.parse("second").should eq("second")
				param.parse("third").should eq("third")

				expect {
					param.parse("anything else")
				}.to raise_exception(Paypal::InvalidParameter)
			end

			it "should coerce symbols to strings" do
				param = @api::Enum.new("First", "Second", "ThirdThing")

				param.parse(:first).should eq("First")
				param.parse(:second).should eq("Second")
				param.parse(:third_thing).should eq("ThirdThing")

				expect {
					param.parse(:anything_else)
				}.to raise_exception(Paypal::InvalidParameter)
			end
		end

		describe Paypal::Api::Coerce do
			it "should allow a well formed coercion" do
				param = @api::Coerce.new( lambda { |val| return [1, "1", true].include?(val) ? 1 : 0 } )

				param.parse(1).should eq(1)
				param.parse("1").should eq(1)
				param.parse(true).should eq(1)

				param.parse(23).should eq(0)
				param.parse("adfa").should eq(0)
			end
		end

		describe Paypal::Api::Sequential do
			before do
				class Test < @api
					set_request_signature :tester, {
						:sequential => @api::Sequential.new({:l_string => String, :l_fixnum => Fixnum, :l_set_category => Optional.new(String)})
					}
				end

				@request = Test.tester
				@request.sequential.push({:l_string => "sasdf", :l_fixnum => 23, :l_set_category => "asdfasdf"})


				expect {
					@request.sequential.push({:l_string => "sass"})
				}.to raise_exception Paypal::InvalidParameter

				expect {
					@request.sequential.push({:l_string => "sass", :l_fixnum => "string"})
				}.to raise_exception Paypal::InvalidParameter
			end

			it "should allow nestedly defined params" do
				@request.sequentials_string.should include("sasdf")
				@request.sequentials_string.should include("23")
			end

			it "should allow optional params" do
				@request.sequential.push({:l_string => "alf", :l_fixnum => 22})
				@request.sequentials_string.should_not include("L_SETCATEGORY1")
			end

			it "should number the items" do
				@request.sequential.push({:l_string => "alf", :l_fixnum => 22})
				@request.sequentials_string.should include("L_FIXNUM1")
				@request.sequentials_string.should include("L_SETCATEGORY0")
			end

			it "should keep the first underscore" do
				param = @api::Sequential.new({:l_test => String})
				param.to_key(:l_test).should eq("L_TEST")
				param.to_key(:l_set_category).should eq("L_SETCATEGORY")
			end
		end

		describe Paypal::Api::Optional do

			it "should allow optional enum" do
				param = @api::Optional.new(@api::Enum.new("test", "tamp"))

				expect {
					param.parse("tisk")
				}.to raise_exception(Paypal::InvalidParameter)

				param.parse("test").should eq("test")
			end

			it "should allow optional regexp" do
				param = @api::Optional.new(/test/)

				expect {
					param.parse("tisk")
				}.to raise_exception(Paypal::InvalidParameter)

				param.parse("test").should eq("test")
				param.parse(" sdf a test").should eq("test")
			end

			it "should allow optional class specifiers" do
				param = @api::Optional.new(String)

				expect {
					param.parse(2)
				}.to raise_exception(Paypal::InvalidParameter)

				param.parse("test").should eq("test")
				param.parse(" sdf a test").should eq(" sdf a test")
			end
		end
	end
end