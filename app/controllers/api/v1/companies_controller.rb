class Api::V1::CompaniesController < ApplicationController
  include RackSessionFix

  before_action :authenticate_user!
  before_action :validate_file_param, only: :import

  def index
    @companies = Company.includes(:addresses)
    render :index
  end

  def show
    @company = Company.find(params[:id])
    render :show
  rescue ActiveRecord::RecordNotFound
    @title = "Company Not Found"
    @status = 404
    render :error_response, status: :not_found
  end

  def create
    @company = Company.new(company_params)

    if @company.save
      render :create, status: :created
    else
      @title = "Validation Failed"
      @status = 422
      render :error_response, status: :unprocessable_entity
    end
  end

  def import
    import_result = CompaniesImportService.new(params[:file]).call
    @invalid_rows = import_result.invalid_rows
    @companies = Company.where(id: import_result.imported_company_ids).includes(:addresses)
    render :import
  end

  private

  def company_params
    params.require(:company).permit(:name, :registration_number, addresses_attributes: %i[street city postal_code country company])
  end

  def validate_file_param
    unless params[:file].present?
      @title = "File Not Found"
      @status = 400
      render :error_response, status: :bad_request and return
    end

    unless valid_file_type?
      @title = "Invalid File Type"
      @status = 422
      render :error_response, status: :unprocessable_entity and return
    end
  end

  def valid_file_type?
    %w[text/csv application/octet-stream].include?(params[:file].content_type)
  end
end
