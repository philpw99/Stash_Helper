# Notice: stash v17 compatibility
Because v17 is using a very different file structure, my Stash_Helper 2.3.12 and below will not work properly with it.
To use v17 with Stash_Helper, you need Stash_Helper v2.4.1 and above. <p>
To be perfectly clear:
* If you are using Stash v16.1 or below, use Stash_Helper v2.3.12 or below.
* If you are using Stash v17 or above, use Stash_Helper v2.4.1 or above.
<p>
Personally I don't recommend upgrade to v17 yet, because there is an issue needs to be addressed. The previous file scans from v12 will generate file paths like 
`g:my folder\my video.mp4` , instead of the normal `g:\my folder\my video.mp4`. The upgrades from v12 to v16 didn't fix this problem at all, they just leave the path as it is. Now in V17 if you do a scan with file path like that, you will end with 2 file entries and 2 parent_folder_ids, because Stash v17 will think `g:my folder` and `g:\my folder` are different folders, thus the file paths are also different. I got over 900 duplicate entries because of it.

The easy fix for this is to revert the sqlite database to the v16 one then using 
```
UPDATE scene SET path = "g:\" || substr( path, 2) WHERE substr( path, 1, 2) = "g:" AND substr( path, 3, 1) != "\"
```
to fix the small error in path. After that Stash v17 will handle the paths correctly.

# Stash_Helper
<a href='https://github.com/stashapp/stash'>StashApp</a> is a powerful content management program for your porn collections. It's cross-platform and comes with many website scrapers. It will make your whole video collection looks professional: with detail info about scenes, performers, studios...etc. It's like what Plex has done for your movie collections.<br>
Though Stash is powerful. It comes with just a console window and not super easy to use for the beginners. This program is trying to improve that aspect and add some features to it.
## Features of SH

<table>
  <tr>
   <td><img src="https://user-images.githubusercontent.com/22040708/181331368-2a10e5d2-5d24-4c83-a81c-5c944565257c.png" /></td>
    <td>Merge 2 performers' information to reduce performer duplications.</td>
  </tr>
  <tr>
   <td><img src="https://user-images.githubusercontent.com/22040708/194734010-f076d4e7-7527-4a1a-8944-ddc8c211c490.png" />
   </td>
    <td>Use Alt-P to easily play the Movie/Scene/Image/Gallery in the current browser tab.</td>
  </tr>
  <tr>
   <td><img src="https://user-images.githubusercontent.com/22040708/147078458-74833489-8460-4ba0-bd8b-4ded7263db94.png" /></td>
    <td>(New) Light Gallery photos browsing. Watching images and galleries, well, like a gallery. Just browse to a gallery then hit Alt-P.</td>
  </tr>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/22040708/147073715-633ce13f-4d05-4552-9243-383af6adf974.png" /></td>
    <td>Allow you to choose which browser to run Stash: Firefox, Chrome or MS Edge. It will use the according webdriver to launch Stash web interface.</td>
  </tr>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/22040708/147073952-91165432-05b0-4428-93fd-8d7a942e5710.png" /></td>
    <td>Provide 20 bookmark slots for each category: Scenes, Images, Movies...etc. You can give a short name for that bookmark, like "Good Video", "Nice Actress"...etc, so you can find and launch the page easily. </td>
  </tr>
  <tr>
     <td><img src="https://user-images.githubusercontent.com/22040708/147075069-eec3bfa9-d5a1-401e-a678-f51736981183.png" /></td>
     <td> You can specify a media player to handle the videos/playlists/images. 6 built-in media player presets like VLC, PotPlayer...etc. </td>
  </tr>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/22040708/147077051-3d05ff4e-6b8e-44f2-b676-45c82c84164a.png" /></td>
    <td>Easy to use scraper manager. Installing a new scraper is as easy as a mouse click. It will also check available updates for your installed scrapers, and ask your permission to update.</td>
  </tr>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/22040708/147078060-f4c27a55-11a7-410d-839e-0fecf5008110.png" /></td>
    <td>Create movies from scenes. It will copy the current scene data and create a new movie with it. Or it can create movies by studios.</td>
  </tr>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/22040708/147079136-70f923d9-d26a-41fe-a833-be32ccf0269d.png" /></td>
    <td>CSS Magic to add/remove special CSS Snippets quickly. Usually it works right away, sometimes you need to close the browser to take effect.</td>
  </tr>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/22040708/147079498-a2563ab1-6705-4d5d-a62a-e5a016744d42.png" /></td>
    <td>Powerful playlist creation tool. You can set the scene filter and it will add the resulting files to the list, or you can browse to a scene/movie, hit "Ctrl-Alt-A" to add it to the list, whichever more convenient for you. You can save or load the play list in standard .m3u format. The playlist can be sent to the media player you chose. </td>
  </tr>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/22040708/147080557-e4a4f6d0-ea0d-49f6-bc8f-34dd25c9ac8d.png" /></td>
    <td>Ctrl-Enter is the boss coming key. Hit it and it will immediately close the browser and the media player.</td>
  </tr>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/22040708/147080791-91397c04-5258-4b8e-8726-6cae34e1d06e.png" /></td>
    <td>Stash autoupdate (for v11 and above). Each time SH is launched, it will check the latest version of Stash. If it found the new released version, it will ask you about updating. You can choose to ignore it, update it or just cancel.</td>
  </tr>
  <tr>
    <td><img src="https://user-images.githubusercontent.com/22040708/147081068-416b62bd-38f5-48d1-980a-3f7106df4466.png" /></td>
    <td>One button to scan for new files in your collection.</td>
  </tr>
  <tr>
    <td></td>
    <td>Open the current scene/movie/image's media folder so you can find the files easily.</td>
  </tr>
  
  
</table>

## Shortcomings of SH
* Windows only.
* Some anti-virus programs don't like AutoIt scripts (.a3x). So far no one told me an virus alarm was triggered yet.
* Poor handling of multi-tab browsing due to the limit of webdriver. I recommend using Stash_Helper with single tab browser only.

## Installation
Get the latest release <a href='https://github.com/philpw99/Stash_Helper/releases'>here</a> and just run it. Basically the installer has nothing need to change.

<img src='https://user-images.githubusercontent.com/22040708/138208437-28787926-6a7b-4c1d-9f59-64ca0b489294.png' width=500>

## Running it the first time
After installation now you have this item in your start menu:<p>
<img src='https://user-images.githubusercontent.com/22040708/138208688-82c2f177-7fc7-4741-bd52-55968f7912c7.png' width=200><br>
Click on it, and this welcome screen will show up:<p>
<img src="https://user-images.githubusercontent.com/22040708/138208905-0866b161-55f1-407d-89e8-3a17a6e9156d.png" width=500><p>
Now it's time to browse for that stash-win.exe you downloaded from the "Stash" link above. Or you can click on the "Website" button and go there.<p><p>
The second question is about which browser you want to use to see the content provided by Stash. I recommend Chrome and Edge. Firefox will give you a robot head and a red address bar. Doesn't look good that way.<p>
<img src="https://user-images.githubusercontent.com/22040708/138209311-6d4f61c7-6b8e-4112-ae99-7dc9bd2f436c.png" width=500><p><p>
Then it's all set. There are some extra info I provided for the first time Stash user, and you will see why you need to know them later. Right now just **launch it** already!<p>

Now you should comes to the Stash Wizard screen:<br>
<img src="https://user-images.githubusercontent.com/22040708/138209968-8dace6ce-efff-4a43-96a6-ee973c2dfc6c.png" width=500> <p><p>
Complicated? Hard to understand? Don't be. Just click on "In the current working directory". That's the correct answer 99.9999% of the time.<p><p>
  
The next screen seems less intimidating, just click on the "Add Directory" button, tell Stash where your carefully curated collections are. Then click on "Next"<br>
<img src="https://user-images.githubusercontent.com/22040708/138210908-61981efa-7751-49b1-b94d-68cc160adf6c.png" width=500> <p><p>

This screen is even easier, just click on "Confirm"<br>
<img src="https://user-images.githubusercontent.com/22040708/138211131-46199e20-7844-4831-9fb2-645de597f1a5.png" width=300><p><p>

Once again, it says blah,blah,blah and your instinct is to click on "Finish", right?
<img src="https://user-images.githubusercontent.com/22040708/138211507-2c33a8b5-0656-4ac1-82b0-588f70af59d0.png" width=500><p>
**WRONG** Notice it tells that you need to "...clicking on Tasks, then Scan..."??? Yeah, I did miss that part, and it took me quite a while to figure it out.<p><p>
  
Now you are staring at an empty Stash database and still don't know what went wrong. Didn't you just tell Stash where your em... collections were?<p>
<img src="https://user-images.githubusercontent.com/22040708/138212537-cbfc874e-c445-493c-90f5-18802c22173c.png" width=500> <p><p>
No, this is actually your fault. You need to follow the instructions. Go to the "Settings", click on "Task" then "Scan", like the screen shown here.<p>
<img src="https://user-images.githubusercontent.com/22040708/138212569-5374e995-1e7a-4fd3-9573-3eadf5d81efc.png" width=500><p><p>
Then just like magic, all your video collections are now showing up in the "Scenes","images" and "Galleries"(if you have zipped jpgs).<p>
Because those screens are not "Work Place Safe". So I won't show them here. Just want to congratulate you on your first baby step toward the almighty Stash !
And where is my program fit in? It's hiding in the corner! Look here:<p>
<img src="https://user-images.githubusercontent.com/22040708/138213174-2e4a4500-847d-4304-b55f-5f77272709d0.png"><p>
It's ready to help. Click on it and you will see:<p>
<img src="https://user-images.githubusercontent.com/22040708/138546140-dacd4476-6e53-4f55-b640-1d10c4b3585d.png"><p><p>
  
So what's so special about it? Well, go to the settings, please.<p>
<img src="https://user-images.githubusercontent.com/22040708/138213609-85376330-1d3f-4a7e-a45c-121d54e424d3.png" width=500><p>
You see? Besides you can use your own media player to play your scenes, there is a "Boss Coming Key" for you, in case your boss is really coming toward you at the worst moment. :D <p>
Now the most powerful feature is customizing the menu. Click on "Scenes->Customize...", and you will see this:<p>
<img src="https://user-images.githubusercontent.com/22040708/138214537-3fca6801-4e2d-4200-aad3-eaee459f19aa.png" width=500><p><p>
This is like the bookmark or favorite list. You can give it an descriptive title, then paste the link copied from Stash, like I've shown above.
Next time you can get to the same page easily by using my helper:<p>
<img src="https://user-images.githubusercontent.com/22040708/138546205-ddcb4db2-67ba-4106-aa3d-32d9340015c9.png" width=500> <p><p>
  
The next topic is about "Scraper Manager". This is a very important feature in both Stash and my helper.<p>
<img src="https://user-images.githubusercontent.com/22040708/138546176-7976dbe3-372b-48b3-a5b6-cd9f7d9056e8.png" width=500><p><p>
If you know the website where your downloaded your video, a scraper will help you to retrieve the video information by "scraping" that video's URL.<br>
A scraper will save you tons of time. You don't need to manually type in things like performers, studio, production date, description, video duration...etc. A scraper get those information for you, but you need to know **which** scraper to get. Some scrapers get you great accurate info, some don't. So you need to do the experiments for them. Since I provide you an easy way to install/remove scrapers, it should be a piece of cake.<p>
To use an installed scraper, you choose a scene, click on "Edit" and fill in the "URL" blanket. If that URL fits the scraper's website, an white scraper icon will come up next to URL. Click on that and the scraper will start its work.<p>
Some scrapers don't need URLs, like Performer's scrapers. They just need a name, and they will search a website for that name, and give you the performer's info in return. Stash comes with a performer's scraper: freeones, which is quite good in looking up the performer's info, but personally I like Babepedia scraper more.<p>
One more thing, why Stash has "Movies" that people rarely used? Well, movies are used for Japanese videos, in which one movies usually contains multiple scenes. There is nothing wrong to create a movie for a single-scene video. The movies have front and back cover, and they look really cool on my screen.<p><p><p>

<img src="https://user-images.githubusercontent.com/22040708/138216742-b496e3ba-d8bc-4019-bf1e-37808fe80b3b.jpg" width=300><p><p>
Well, I guess this concludes the readme. There will be more features coming, both in Stash and my little helper. I hope you will find "pleasure" in using them. :D
