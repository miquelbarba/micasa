class FlatController < ApplicationController
  def index
    render :index, locals: { flats: flats.page(page).per(30),
                             count: count,
                             total: total,
                             page: page,
                             headers: headers,
                             next_page: next_page,
                             previous_page: previous_page,
                             neighbourhoods: neighbourhoods,
                             postal_codes: postal_codes,
                             operators: operators,
                             floors: floors,
                             rooms: rooms,
                             created_at: created_at,
                             portals: portals,
                             conservations: conservations,
                             total_count: total_count}
  end

  private
  def flats
    @flats ||= begin
      scope = Flat.order(order_by)
      scope = add_condition(scope, 'neighbourhood', '=', params[:neighbourhood])
      scope = add_condition(scope, 'conservation', '=', params[:conservation])
      scope = add_condition(scope, 'postal_code', '=', params[:postal_code])
      scope = add_condition(scope, 'price', params[:price_op], params[:price])
      scope = add_condition(scope, 'floor', params[:floor_op], params[:floor])
      scope = add_condition(scope, 'rooms', params[:rooms_op], params[:rooms])
      scope = add_condition(scope, 'sq_meters', params[:sq_meters_op], params[:sq_meters])
      scope = add_condition(scope, 'created_at', params[:created_at_op], params[:created_at])
      scope = add_condition(scope, 'portal', '=', portal)
      add_condition(scope, 'price_sq_meter', params[:price_sq_meter_op], params[:price_sq_meter])
    end
  end

  def count
    flats.count
  end

  def total_count
    Flat.where(portal: portal).count
  end

  def created_at
    (10.days.ago.to_date..Date.today).to_a
  end

  def portals
    Flat.select(:portal).distinct.map(&:portal).compact.sort
  end

  def total
    Flat.count
  end

  def neighbourhoods
    Flat.select(:neighbourhood).where(portal: portal).distinct
        .map(&:neighbourhood).compact.sort
  end

  def postal_codes
    Flat.select(:postal_code).where(portal: portal)
        .distinct.map(&:postal_code).compact.sort
  end

  def floors
    Flat.select(:floor).where(portal: portal)
        .distinct.map(&:floor).compact.sort
  end

  def rooms
    Flat.select(:rooms).where(portal: portal)
        .distinct.map(&:rooms).compact.sort
  end

  def conservations
    Flat.select(:conservation).where(portal: portal)
        .distinct.map(&:conservation).compact.sort
  end

  def portal
    params[:portal] || portals.first
  end

  def operators
    %w(<= = >=)
  end

  def page
    (params[:page] || 1).to_i
  end

  def order_by
    if params[:order_field].presence && params[:order_sort].presence
      "#{params[:order_field]} #{params[:order_sort]}"
    else
      'neighbourhood asc'
    end
  end

  def headers
    data = [['neighbourhood', 200], ['price', 60], ['floor', 60], ['rooms', 60],
            ['sq_meters', 60], ['price_sq_meter', 60], ['conservation', 60],
            ['created_at', 60]]
    data.map do |field, width|
      [field, field, next_order(field), width]
    end
  end

  def next_order(field)
    if params[:order_field] == field
      params[:order_sort] == 'asc' ? 'desc' : 'asc'
    else
      'asc'
    end
  end

  def add_condition(scope, field, operator, value)
    if field.presence && operator.presence && value.presence && operator != 'None' && value != 'None'
      scope = scope.where("#{field} #{operator} ?", value)
    end
    scope
  end

  def next_page
    page < num_pages ? page + 1 : nil
  end

  def previous_page
    page > 1 ? page - 1 : nil
  end

  def num_pages
    (total / 30.to_f).ceil
  end
end
