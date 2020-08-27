defmodule Grdbii.Error do
  defmodule TimeoutError do
    defexception code: :internal_server_error,
                 type: :timeout,
                 message: "Server timed out"
  end

  defmodule TooComplex do
    defexception code: :not_acceptable,
                 type: :too_complex,
                 message: "Request is too complex to process"
  end

  defmodule InternalError do
    defexception code: :internal_server_error,
                 type: :unexpected_error,
                 message: "An unexpected error occured on the server"
  end

  defmodule InvalidParameter do
    defexception code: :bad_request,
                 type: :invalid_parameter,
                 message: "Could not parse request parameter"
  end
end
