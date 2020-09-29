#AWS Code is an git repository
git clone https://git-codecommit.us-east-2.amazonaws.com/v1/repos/AWSSampleApp 

#Edit file and push to repo
cd C:\AWS\Code\AWSSampleApp

#Add file to the repository
git add .
#Files are now staged
git status
#Get an info about the new files
git commit -m "Add sampleapp files"
#Commit files to the git repository
#If git isn't configured you have to define the folloing informations:
git config --global user.email "tes@test.com"
git config --global user.name "Demouser"

#Now push the files to the repository
git push


