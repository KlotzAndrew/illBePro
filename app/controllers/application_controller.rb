class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

 before_filter :configure_permitted_parameters, if: :devise_controller?
 before_filter :set_variables

 helper_method :challenge_onboarding, :prize_onboarding

def set_variables
  if user_signed_in?

    @summoner_name_ref = session[:summoner_name_ref_temp]

    if session[:region_id_temp] != nil
      @has_settings = true
    else
      @has_settings = false
    end

    

    if Ignindex.find_by_user_id(current_user.id).nil?
      @ign_id_full = nil
    else
      @ign_id_full = Ignindex.find_by_user_id(current_user.id)
    end


  else #not signed in
    @summoner_name_ref = session[:summoner_name_ref_temp]
     session[:setup_progress] ||= 0
    if session[:region_id_temp] != nil
      @has_settings = true
    else
      @has_settings = false
    end

    ign_id_all = Ignindex.where("summoner_name_ref = ?", @summoner_name_ref)
    if ign_id_all.first.nil?
      @ign_id = "n/a"
    else
      @ign_id = Ignindex.where("summoner_name_ref = ?", @summoner_name_ref).first.id
      if session[:last_validation] == ign_id_all.first.last_validation
        @val_stat = "T"
      else
        @val_stat = session[:last_validation]
      end
    end
  end
end



def challenge_onboarding
	@status_onboarding = Status.all.where("user_id = ?", current_user.id).count
end

def prize_onboarding
	@prize_onboarding = Geodeliver.find_by_user_id(current_user.id).address
end

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:first_name, :last_name, :profile_name, :email, :password, :password_confirmation, :remember_me, :summoner_name, :summoner_id) }

  end


end
