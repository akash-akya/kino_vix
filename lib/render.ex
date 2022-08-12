defimpl Kino.Render, for: Vix.Vips.Image do
  alias Vix.Vips.Operation
  alias Vix.Vips.Image

  def to_livebook(image) do
    height = Image.height(image)

    preview =
      if height > 200 do
        Operation.resize!(image, 200 / height)
      else
        image
      end

    {:ok, buf} = Image.write_to_buffer(preview, ".png")

    Kino.Layout.grid([Kino.Image.new(buf, "image/png"), image_info(image)])
    |> Kino.Render.to_livebook()
  end

  defp image_info(image) do
    height = Image.height(image)
    width = Image.width(image)
    {:ok, filename} = Image.header_value_as_string(image, "filename")
    bands = Image.bands(image)

    """
    <span style="color: #61758a;">
      <code>#{filename},  #{width}x#{height} #{format(image)},  #{bands} bands,  #{interpretation(image)}</code>
    </span>
    """
    |> Kino.Markdown.new()
  end

  defp format(image) do
    case Image.format(image) do
      :VIPS_FORMAT_UCHAR -> "8-bit unsigned integer"
      :VIPS_FORMAT_CHAR -> "8-bit signed integer"
      :VIPS_FORMAT_USHORT -> "16-bit unsigned integer"
      :VIPS_FORMAT_SHORT -> "16-bit signed integer"
      :VIPS_FORMAT_UINT -> "32-bit unsigned integer"
      :VIPS_FORMAT_INT -> "32-bit signed integer"
      :VIPS_FORMAT_FLOAT -> "32-bit float"
      :VIPS_FORMAT_COMPLEX -> "64-bit complex"
      :VIPS_FORMAT_DOUBLE -> "64-bit float"
      :VIPS_FORMAT_DPCOMPLEX -> "128-bit complex"
    end
  end

  defp interpretation(image) do
    case Image.interpretation(image) do
      :VIPS_INTERPRETATION_MULTIBAND -> "multiband"
      :VIPS_INTERPRETATION_B_W -> "mono"
      :VIPS_INTERPRETATION_HISTOGRAM -> "histogram"
      :VIPS_INTERPRETATION_XYZ -> "XYZ"
      :VIPS_INTERPRETATION_LAB -> "Lab"
      :VIPS_INTERPRETATION_CMYK -> "CMYK"
      :VIPS_INTERPRETATION_LABQ -> "LabQ"
      :VIPS_INTERPRETATION_RGB -> "RGB"
      :VIPS_INTERPRETATION_UCS -> "UCS"
      :VIPS_INTERPRETATION_LCH -> "LCh"
      :VIPS_INTERPRETATION_LABS -> "LabS"
      :VIPS_INTERPRETATION_sRGB -> "sRGB"
      :VIPS_INTERPRETATION_YXY -> "Yxy"
      :VIPS_INTERPRETATION_FOURIER -> "Fourier"
      :VIPS_INTERPRETATION_RGB16 -> "RGB16"
      :VIPS_INTERPRETATION_GREY16 -> "GREY16"
      :VIPS_INTERPRETATION_ARRAY -> "Array"
      :VIPS_INTERPRETATION_scRGB -> "scRGB"
    end
  end
end
