import os
import functions_framework
import google.generativeai as genai
from firebase_functions import https_fn
from firebase_admin import initialize_app

# Inicializa la aplicación de Firebase Admin SDK (necesario para funciones)
initialize_app()

@https_fn.on_request()
def callGeminiApi(req: https_fn.Request) -> https_fn.Response:
    """
    Función HTTP de Firebase que llama a la API de Gemini.
    Recibe un prompt y devuelve la respuesta de Gemini.
    """
    try:
        # Obtener la clave de API de Gemini de las variables de entorno
        # ¡IMPORTANTE! Esto se configurará en Firebase después de escribir el código.
        gemini_api_key = os.environ.get("GEMINI_API_KEY")
        if not gemini_api_key:
            return https_fn.Response("Error: GEMINI_API_KEY no configurada.", status=500)

        genai.configure(api_key=gemini_api_key)

        # Obtener el prompt del cuerpo de la solicitud (enviado desde Flutter)
        request_json = req.get_json(silent=True)
        if request_json and 'prompt' in request_json:
            user_prompt = request_json['prompt']
        else:
            return https_fn.Response("Error: 'prompt' no encontrado en la solicitud.", status=400)

        # Inicializar el modelo Gemini
        model = genai.GenerativeModel('gemini-pro')

        # Generar contenido con Gemini
        response = model.generate_content(user_prompt)

        # Devolver la respuesta de Gemini
        return https_fn.Response(response.text, status=200, headers={"Content-Type": "text/plain"})

    except Exception as e:
        # Manejo de errores
        print(f"Error al llamar a Gemini API: {e}")
        return https_fn.Response(f"Error interno del servidor: {e}", status=500)