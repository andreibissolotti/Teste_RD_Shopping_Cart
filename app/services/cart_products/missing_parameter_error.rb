module CartProducts
  class MissingParameterError < StandardError
    def initialize(param_name)
      super("Parâmetro: #{param_name} é obrigatório")
    end
  end
end
