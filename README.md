# PopMedia
Welcome to PopMedia's GitLab repository.

PopMedia is the social multimedia review app and there is nothing like it out there! It’s intended for bookworms, movie buffs and binge watchers alike. The goal is to create a rich user experience involving writing reviews, leaving comments on friends’ posts, finding your new favorite series, then snapping a photo to wrap it up once the series is done.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Frontend
See Resolving Environment Issues if having ios difficulties
To have top bar and navigation bar use main scaffold

## Database
Our database is located on Supabase
Before running application in the terminal run:
flutter pub get

## Backend
Our backend server code is written in Python.  

Here's what to do before running python code:  
Install [UV](https://docs.astral.sh/uv/) onto your computer using the following commands in your terminal.  
1. `curl -LsSf https://astral.sh/uv/install.sh | sh` if on MacOS or Linux.  
    ```powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"``` if on Windows
2. Start a new terminal
3. In the new terminal, navigate to the repo and enter the `backend` folder.
4. run `uv sync`

Now UV should have handled all the package dependencies for the python code in the backend folder. You can run test code by using `uv run [program].py`.

To Host Backend Locally (Windows):
    In terminal:
1. cd into the backend
2. source .\\.venv\Scripts\activate 
3. fastapi dev controller.py  
(when ready should output: Application startup complete)

To Host Backend Locally (MacOS):
    In terminal:
1. cd into the backend
2. source ./.venv/bin/activate 
3. fastapi dev controller.py
(when ready should output: Application startup complete)

Once locally hosted, you can visit http://127.0.0.1:8000/docs to use the swagger testing UI.  
This also works with the server! visit http://34.214.182.227:8000/docs to test the remote.



**Bonus:**
`uv run ruff check .` executes a linter (style and error checker) for the code in the folder. 

`uv run pytest` will search and run
- Files named `test_*.py` or `*_test.py`
- Functions starting with `test_`

and inform you whether `assert` statements were satisfied or not.


## Media is of form:
    - title: str (title of the media)
    - description: str (description of the media)
    - overall_rating: float (rating of the media)
    - id: str (unique identifier of structure:  b<isbn> for books, m<int> for movies, t<int> for tv shows)
    - image: str (url to image of the media)
    - api_review_count: int (number of reviews from the API)
    - genres: list (list of genres the media belongs to) 
    - release_date: str (release date of the media)
    - creator: str

if any of the fields are missing from the original data, they will be filled with default values:
    - for string fields: 'N/A'
    - for int/float fields: -1.0

## DataService
When building a DataService method, please add the following code.  
```
final user = FirebaseAuth.instance.currentUser!;  
final token = await user.getIdToken();
``` 
near the top of the method.  
  
```
headers: {  
    'Authorization': 'Bearer $token',  
},
```
as an argument for http.get or http.post.  
e.g.  
```
final response = await http.post(uri,  
    headers: {  
        'Authorization': 'Bearer $token',  
    },  
);
```

## Controller
Controller methods that accept userIds as argument require an additional 'credentials' argument.  
```
credentials: HTTPAuthorizationCredentials = Depends(security)
```  
Here's an example:  
```
@app.get("/fetchFollowers")
async def fetchFollowers(following_id: str,  
                          credentials: HTTPAuthorizationCredentials = Depends(security)):
```  
Somewhere near the start of your code, you should have this snippet:  
```
token = credentials.credentials  
decoded = auth.verify_id_token(token)  
if (uid == "me"):  
    uid = "decoded["uid"]
```  
this checks if the argument is 'me' and uses firebase to extract the user's Id. Which can be trusted!
You can now run permission checks on the provided userId if needed. 
