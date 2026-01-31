module CartProducts
  class MissingParameterError < StandardError
    def initialize(param_name)
      super("Parâmetro: #{param_name} é obrigatório")
    end
  end

  class QuantityInvalidError < StandardError
    def initialize
      super("Quantidade deve ser maior que 0")
    end
  end
end
