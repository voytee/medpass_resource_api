require 'singleton'

module MedpassResourceApi

  USER_ARGS = [:login, :password, :group_id].freeze
  PERSONAL_PROFILE_ARGS = [:email, :first_name, :last_name, :dob, :address, :postcode, :city, :phone, :mobile, :occupation_id, :nd, :gadu, :skype, :city_id, :province_id, :title, :biography]
  SPECIALTY_PROFILE_ARGS = [:pwz, :specialty_id]
  
  class Configuration
    attr_accessor :api_key
    attr_accessor :medpass_url
  end

  def self.configure(&block)
    Base.configure(&block)
  end
  
  def self.configuration
    Base.configuration
  end
  
  class Base
    
    @@configuration = nil
    
    def self.configuration
      @@configuration
    end
    
    def self.configuration=(val)
      @@configuration = val
    end
    
    def self.configure
      self.configuration ||= Configuration.new
      yield(configuration)
    end

    
    def self.register_user(group_id = 1, args = {}, portal_name = nil)
      arguments = {:user => get_user_args(args, group_id, portal_name), :personal_profile => get_personal_profile_args(args)}
      begin
        res = MedpassUser.post(:register, :api_key => @@configuration.api_key, :args => arguments)
        wrap_result(JSON.parse(res.response.body))
      rescue ActiveResource::ResourceInvalid => error
        wrap_error(error)
      end
    end
    
    def self.register_doctor(args = {}, portal_name = nil)
      arguments = {:user => get_user_args(args, 2, portal_name), 
                   :personal_profile => get_personal_profile_args(args), 
                   :specialty_profile => get_specialty_profile_args(args)}
      begin
        res = MedpassUser.post(:register, :api_key => @@configuration.api_key, :args => arguments)
        wrap_result(JSON.parse(res.response.body))
      rescue ActiveResource::ResourceInvalid => error
        wrap_error(error)
      end
    end

    def self.get_user(login_or_openid_url, timestamp = nil)
      login = get_login(login_or_openid_url)
      res = begin
              MedpassUser.find(login, :params =>{:timestamp => timestamp, :api_key => @@configuration.api_key})
            rescue ArgumentError
              nil
            end
      wrap_result(res)
    end
    
    def self.get_user_profile(login_or_openid_url, timestamp = nil)
      login = get_login(login_or_openid_url)
      res = begin
              MedpassUser.find(login, :params =>{:timestamp => timestamp, :full_profile => true, :api_key => @@configuration.api_key})
            rescue ArgumentError
              nil
            end
      wrap_result(res)
    end
    
    def self.get_user_friends(login_or_openid_url)
      login = get_login(login_or_openid_url)
      wrap_result(MedpassUserFriend.find(:all, :params => {:user_id => login, :api_key => @@configuration.api_key}))
    end
    
    
    def self.get_user_message(login_or_openid_url, id)
      login = get_login(login_or_openid_url)
      wrap_result(MedpassMessage.find(id, :params => {:user_id => login, :api_key => @@configuration.api_key}))
    end
    
    def self.get_user_messages(login_or_openid_url, options = {})
      login = get_login(login_or_openid_url)
      if ['read','received','sent'].include? options[:scope].to_s
        wrap_result(send("get_user_#{options[:scope]}_messages", login, options)) 
      else
        wrap_result(nil)
      end
    end 
    
    def self.get_user_received_messages(login_or_openid_url, options = {})
      login = get_login(login_or_openid_url)
      wrap_result(MedpassMessage.find(:all, :params => {:user_id => login, :api_key => @@configuration.api_key}.merge(options)))
    end
    
    def self.get_user_read_messages(login_or_openid_url, options = {})
      login = get_login(login_or_openid_url)
      wrap_result(MedpassMessage.get(:read, :user_id => login, :limit => options[:limit], :app => options[:app], :api_key => @@configuration.api_key))
    end
    
    def self.get_user_unread_messages(login_or_openid_url, options = {})
      login = get_login(login_or_openid_url)
      wrap_result(MedpassMessage.get(:unread, :user_id => login, :limit => options[:limit], :app => options[:app], :api_key => @@configuration.api_key))
    end
    
    def self.get_user_sent_messages(login_or_openid_url, options = {})
      login = get_login(login_or_openid_url)
      wrap_result(MedpassMessage.get(:sent, :user_id => login, :limit => options[:limit], :app => options[:app], :api_key => @@configuration.api_key))
    end

    def self.get_user_args(args, group_id, portal_name)
      returning Hash.new do |hash| 
        USER_ARGS.each{|k| hash[k] = args[k]}
        hash[:group_id] = group_id
        hash[:portal_name] = portal_name
      end
    end
    
    def self.get_personal_profile_args(args)
      returning Hash.new do |hash| 
        PERSONAL_PROFILE_ARGS.each{|k| hash[k] = args[k]}
      end
    end
    
    def self.get_specialty_profile_args(args)
      returning Hash.new do |hash| 
        SPECIALTY_PROFILE_ARGS.each{|k| hash[k] = args[k]}
      end
    end
    
    
    def self.wrap_result(result)
      result.is_a?(Array) ? wrap_all(result) : wrap_one(result)
    end

    def self.wrap_error(error)
      ErrorResult.new(error)
    end
    
    def self.wrap_one(result)
      return NilResult.instance if result.nil?
      Result.new(result) 
    end
    
    def self.wrap_all(results)
      return NilResult.instance if results.nil?
      Result.build_all(results) 
    end
    
    def self.get_login(login_or_openid_url)
      core_medpass_url = configuration.medpass_url.split("http://").last
      login_or_openid_url.gsub("/","").gsub('.beta.','.').split(".#{core_medpass_url}").last.gsub("http:","").gsub(".","-dot-")
    end
    
  end
  

  class ErrorResult
    attr_reader :raw_errors
    def initialize(error)
      @raw_errors = JSON.parse(error.response.body)
    end

    def errors_on(field)
      @raw_errors[field.to_s] rescue nil
    end
    
    def first_error_on(field)
      errors_on(field).first rescue errors_on(field)
    end
    
    def errors
      self.raw_errors
    end

  end
  
  
  class NilResult
    include Singleton
    attr_accessor :raw_result
  end
  
  
  class Result

    attr_reader :raw_result, :resource_type
    
    def initialize(result)
      @raw_result = result
    end
    
    # Nie wywalamy skryptu nawet jesli odwolamy sie do czegos czego dany obiekt nie posiada 
    def method_missing(method_name, *args)
      return @raw_result.send(method_name) if @raw_result.respond_to?(method_name)
      return @raw_result[method_name.to_s] rescue "brak"
    end

    def self.build_all(results)
      returning [] do |result_list|
        results.each{|result| result_list << self.new(result)}
      end
    end
    
   
  end

  
end
