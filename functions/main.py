# Importa los módulos necesarios de Firebase
from firebase_admin import initialize_app
from firebase_functions import https_fn, options
import google.generativeai as genai

# (Opcional pero recomendado) Fija la región para tus funciones
options.set_global_options(region="europe-west1")

# Inicializa Firebase
initialize_app()

# Define el secreto donde guardaste tu API key
GEMINI_API_KEY = options.SecretParam("GEMINI_API_KEY")

@https_fn.on_call(secrets=[GEMINI_API_KEY])
def callGeminiApi(req: https_fn.CallableRequest):
    """
    Función Invocable (Callable Function) que llama a la API de Gemini de forma segura.
    """
    # 1. VERIFICACIÓN DE SEGURIDAD AUTOMÁTICA
    # Si el usuario no está autenticado, esta línea dará un error y la función se detendrá.
    if req.auth is None:
        raise https_fn.HttpsError(
            code="unauthenticated",
            message="La función solo puede ser llamada por usuarios autenticados."
        )

    # 2. OBTENER LOS DATOS DE FORMA SENCILLA
    # El prompt viene directamente en req.data
    user_prompt = req.data.get("prompt")
    if not user_prompt:
        raise https_fn.HttpsError(
            code="invalid-argument",
            message="La función debe ser llamada con un argumento 'prompt'."
        )

    try:
        # 3. CONFIGURAR GEMINI CON EL SECRETO
        genai.configure(api_key=GEMINI_API_KEY.value())
        model = genai.GenerativeModel('gemini-pro')

        # Combina el prompt del sistema con el del usuario
        system_prompt = "Eres un asistente de bienestar personal, amigable y empático llamado MentalApp Assistant. Tu objetivo es escuchar, ofrecer apoyo y guiar al usuario en su reflexión. No des consejos médicos. Mantén las respuestas concisas y conversacionales."
        full_prompt = f"{system_prompt}\n\nMensaje del usuario: {user_prompt}"

        # Generar contenido
        response = model.generate_content(full_prompt)

        # 4. DEVOLVER LA RESPUESTA
        return {"text": response.text}

    except Exception as e:
        print(f"Error al llamar a Gemini API: {e}")
        raise https_fn.HttpsError(
            code="internal",
            message="No se pudo obtener una respuesta del asistente."
        )