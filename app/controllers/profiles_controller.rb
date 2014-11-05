class ProfilesController < ApplicationController
  
  def show

  	account_update_params = devise_parameter_sanitizer.sanitize(:account_update)

  	 if account_update_params[:password].blank?
      account_update_params.delete("password")
      account_update_params.delete("password_confirmation")
    end

  	@user = User.find_by_id(params[:id])
  	if @user
  		@statuses = @user.statuses.all
  		render action: :show

   	else
  		render file: 'public/404', status: 404, formats: [:html]
  	end
  end

  def update
  end
end
