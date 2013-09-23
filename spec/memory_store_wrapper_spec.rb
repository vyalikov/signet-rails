require 'minitest/spec'
require 'minitest/autorun'
require 'spec_helper'
require 'signet/rails/wrappers/memory_store.rb'

describe Signet::Rails::Wrappers::MemoryStore do

  it "has first_or_create self method that creates user if there is no user with such id" do
    store = Signet::Rails::Wrappers::MemoryStore

    user1 = store.first_or_create_user '12345', :google
    user2 = store.first_or_create_user '123456', :google

    user2.should_not == user1

    user3 = store.first_or_create_user '12345', :google
    user4 = store.first_or_create_user '123456', :google

    user3.should == user1
    user4.should == user2
  end

  it "has get_or_initialize_user_credentials method that creates user credentials or return it if exists" do

    store = Signet::Rails::Wrappers::MemoryStore
    user = store.first_or_create_user '12345', :google

    credentials = store.get_or_initialize_user_credentials user, :google

    credentials2 = store.get_user_credentials user, :google


    credentials.should == credentials2
  end

  it "saves credentials data only when save function has been called" do

    store = Signet::Rails::Wrappers::MemoryStore

    # not saved credentials
    user = store.first_or_create_user '12345', :google
    user.credentials[:signet] = { a: 123 }

    user2 = store.get_user_by_id store.generate_uid('12345', :google)
    user2.credentials[:signet].should == nil

    # saved credentials
    user3 = store.first_or_create_user '1234', :google
    user3.credentials[:singet] = { a: 123 }
    store.save! user3

    user4 = store.get_user_by_id store.generate_uid('1234', :google)
    user4.credentials[:singet][:a].should == 123

  end

end