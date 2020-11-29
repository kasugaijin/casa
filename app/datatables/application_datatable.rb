class ApplicationDatatable
  attr_reader :base_relation, :params

  def initialize(base_relation, params)
    @base_relation = base_relation
    @params = params
  end

  def as_json(*)
    {
      data: sanitize(data),
      recordsFiltered: filtered_records.size,
      recordsTotal: base_relation.size
    }
  end

  private

  def sanitize(data)
    if data.is_a? Array
      data.map { |datum| sanitize datum }
    elsif data.is_a? Hash
      data.transform_values! { |value| sanitize value }
    else
      ERB::Util.html_escape data
    end
  end

  def filtered_records
    raw_records
  end

  def paginated_records
    filtered_records
      .offset(offset)
      .limit(limit)
  end
  alias_method :records, :paginated_records

  def additional_filters
    @additional_filters ||= params[:additional_filters] || {}
  end

  def search_term
    @search_term ||= params[:search][:value]
  end

  def build_order_clause
    Arel.sql "#{order_by} #{order_direction}" if order_by.present?
  end

  def order_by
    @order_by ||=
      lambda {
        order_by = params[:columns][order_column_index][:name]
        order_by if self.class::ORDERABLE_FIELDS.include? order_by.try :downcase
      }.call
  end

  def order_column_index
    params[:order]["0"][:column]
  end

  def order_direction
    order_direction = params[:order]["0"][:dir] || "ASC"
    %w[asc desc].include?(order_direction.downcase) ? order_direction : "ASC"
  end

  def limit
    (params[:length] || 10).to_i
  end

  def offset
    params[:start].to_i
  end

  def bool_filter(filter)
    # expects filter to be an array

    if filter.blank?
      "FALSE"
    elsif filter.length > 1
      "TRUE"
    else
      yield
    end
  end
end
