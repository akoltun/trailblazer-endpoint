require "trailblazer/endpoint"

module Trailblazer::Endpoint::Handlers
  class JSON
    def initialize(controller, options)
      @controller = controller
    end

    attr_reader :controller

    def call
      ->(m) do
        m.not_found { |result| handle_not_found(result) }
        m.unauthenticated { |result| handle_authenticated(result) }
        m.present { |result| handle_success(result) } # DISCUSS : Do we really need this?
        m.created { |result| handle_created(result) }
        m.success { |result| handle_success(result) }
        m.invalid { |result| handle_invalid(result) }
        m.failure { |result| handle_failure(result) }
      end
    end


    private

    def handle_authenticated(result)
      controller.head 401
    end

    def handle_not_found(result)
      if result['result.model']
        controller.render json: get_render_error_representer(result).new(result["result.model"]).to_json, status: 404
      else
        controller.head 404
      end

    end

    def handle_created(result)
      if result["model"]
        controller.render json: get_render_success_representer(result).new(result["model"]), status: 201
      else
        controller.head 201
      end
    end

    # TODO: make this more generic to match all available contract errors and perhaps combine them ??
    def handle_invalid(result)
      controller.render json: get_render_error_representer(result).new(result["result.contract.default"]).to_json, status: 422
    end

    # DISCUSS : what should we return here, operation fails but we don't know why...
    def handle_failure(result)
      controller.render json: get_render_error_representer(result).new(Struct.new(:errors).new(errors: 'Something went wrong')).to_json, status: 500
    end


    def handle_success(result)
      if result["model"]
        controller.render json: get_render_success_representer(result).new(result["model"]), status: 200
      else
        controller.render 200
      end
    end

    def get_render_success_representer(result)
      renderer = result['representer.render.class'] || result["representer.default.class"]
      raise RuntimeError, "Could not determine success representer to use !" unless renderer # DISCUSS add a generic handler somehow, perhaps set this in a parent operation ?

      renderer
    end

    def get_render_error_representer(result)
      renderer = result['representer.error.class']
      raise RuntimeError, "Could not determine error representer to use !" unless renderer # DISCUSS add a generic handler somehow, perhaps set this in a parent operation ?

      renderer
    end
  end

end
