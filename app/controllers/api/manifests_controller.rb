class Api::ManifestsController < Api::ApplicationController
  def update
    @user = User.find_by_nickname(params[:user])
    raise ActiveRecord::RecordNotFound if @user.nil?

    @manifest = @user.manifests.find_or_create_by(name: params[:name])

    @projects = []
    Oj.load(params[:packages]).each do |platform, pkgs|
      pkgs.each do |name|
        @projects << Project.platform(platform).where('lower(name) = ?', name.downcase).first.try(:id)
      end
    end
    @projects.compact!

    @existing = @manifest.subscriptions.map(&:project_id)

    @manifest.subscriptions.where(project_id: (@existing - @projects)).delete_all
    (@projects - @existing).each do |project_id|
      @manifest.subscriptions.create(project_id: project_id)
    end

    render json: nil, status: :ok
  end
end
