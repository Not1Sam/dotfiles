import geocoder
import python_weather as pw
import asyncio
import json
 
async def get_weather():
    async with pw.Client() as clent:
        g = geocoder.ip('me')
        weather = await clent.get(g.city)
        
        icon = weather.kind.emoji
        temp = weather.temperature
        feel = weather.feels_like
        
        data = {
            "text":f"{icon} {temp}°C",
            "tooltip":f"{weather.description} (Feels like: {feel}°C) in {g.city}",  
            "class":weather.description.split()[0].lower()
        }    
    print(json.dumps(data), flush=True)
    

if __name__ == "__main__":
    try:
        asyncio.run(get_weather())
    
    except Exception as e:
        error = {
            "text": "Error",
            "tooltip": f"Error",
            "class": "Error"
        }
        print(json.dumps(error), flush=True)
        
        