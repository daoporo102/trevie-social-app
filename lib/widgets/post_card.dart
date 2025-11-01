import 'package:flutter/material.dart';
import 'package:social_media_app/utils/colors.dart';

class PostCard extends StatelessWidget {
  const PostCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: mobileBackgroundColor,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        children: [
          //HEADER SECTION OF THE POST
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 16,
            ).copyWith(right: 0),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundImage: NetworkImage(
                        'https://hips.hearstapps.com/hmg-prod/images/apple-m4-macbook-pro-lead-672b861685fd0.jpg?crop=0.6666666666666666xw:1xh;center,top&resize=640:*',
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'username',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '2 hours ago',
                              style: TextStyle(
                                color: secondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => Dialog(
                            child: ListView(
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shrinkWrap: true,
                              children: ['Delete', 'Edit']
                                  .map(
                                    (e) => InkWell(
                                      onTap: () {},
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 12,
                                          horizontal: 16,
                                        ),
                                        child: Text(e),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'This is a sample post caption to illustrate the PostCard widget in our social media app.',
                        style: TextStyle(color: primaryTextColor),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          //IMAGE SECTION OF THE POST
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.35,
            width: double.infinity,
            child: Image.network(
              'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQABAAD/2wCEAAkGBxEQERAQEBMQFRAVEBUQEA8QEBcPDxUQFRYaFxcVFRUZHCggGBolGxcVITEhJSkrLi4uFx8zODMsNygtLisBCgoKDg0NFQ0PFSsZFRkrKy0rKysrKzc3Ky0rLS0rKy0tNzcrNzc3Nys3Ky0rKy0rLSsrKysrKysrKysrKysrK//AABEIAMUBAAMBIgACEQEDEQH/xAAcAAEAAQUBAQAAAAAAAAAAAAAAAwECBAUHBgj/xABLEAABAwEEBAgLBQQJBQEAAAABAAIRAwQSIVEFMUGSExQiU2FygZEGBxUXJVJxs9HS4TJCk6HwFqKxwQgjM0Nic5Sj02OCg7TCNf/EABUBAQEAAAAAAAAAAAAAAAAAAAAB/8QAGREBAQEAAwAAAAAAAAAAAAAAABEBIUGB/9oADAMBAAIRAxEAPwDsqIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICIiAiIgIiICgt9sp0Kb61VwbTY0ve86g0Kdarwr0dxqxWyzjXUs1RjevdN396EHkK3jk0Y1zmgV3AGLzRTunpHL1Kzzz6N9W0d1P51wSx8CWNvEh2o8mVPds+Z3VYO6+efRuVfuZ86eebRuVfdZ864Xds+Z3FUNs2btz6pB3PzzaNyr7rPnTzzaNyr7rPnXDbtmzdufVVu2bN259Ug7j55tGZV91nzp55tGZV91nzrh92y5u3Pql2y5u3PqkHcPPNozKvus+dPPNozKvus+dcOLLJm/c+qpwVjzfu/VIO5eebRmVfdZ86eebRmVfdZ864bwVjzfu/VLtkzfufVIO5eebRuVfdZ86eebRmVfdZ864hSslleYFS6T6zSB3quk/BzgxIIiJBBkEJB27zzaNyr7rPnTzzaNyr7rPnXzjUplpgra6J0DUrnBQd5882jcq+6z5088+jcq/cz51xW16FoUCW1Krb4wLG8sg5GNR6CtfWsdM/YM+3BWDvPnn0b6to7qfzqSzeOLRj3NaeGaCYvuFMNHSeXqXzjVowYUbGEkNAJJMADWScAAoPtCyWllamyrTcHU3sbUY4aixwkHuKlWHoWwCzWez2caqVCnR3Ghs/ksxAREQEREBERAREQFUKiIPkTw20cbJpC22fUGWmpcA1cG43mfulq0t4rpXj/ANG8FpNtYDk17Ox5OdSnNM/utZ3rnthshqOjYggZeOAk+xZ1n0VXfqaV6uy2KzWSmKtfAfdaBL3nJo2/wWst3hnVMtszKdFmw3RUqn2kiB2DtVgxqfgvaTsPcr3eC9ca73cte/Sdrq/aq13dHCOu9gmFZxescbp7U4GefB2rmVT9n6nSsHi1b1CqcXreqUGcdA1OlWnQVTpWFwFX1VQ0avqoM06Ef0o3QVQ5rB4Gp6qtNnqeqg9DZNCNZyq1RjGja9waodJ6UYTcpE8G0XWk4XszB1a1oTQePuqJ8jXKUT3rzwvb6MrGjZa1RphwpkNcNYceSCOmSF4axjlBestdW7YnD1nMb3G9/wDKuI8rXcs/RVEvIWtrFbzQFVoc2VMVj+EDA2qWj7rWg+0if4ELN8W+juM6VsFI6uHbVd1aU1SD7QyO1YGn2uNeqdjnFzTsLdkdkDsXQP6PWjb9utNoOqjZrg/zKrhB3WP700d/REUBERAREQEREBERAREQcl/pFaNv2SyWkDGlXdSJHqVWzJ7aY71x7QrgC1fSPjS0bxnRNuZtbR4dsa5okVPzDSO1fMWj6kQrgyvCSu6pWdJ5LQGMGwCAT3mStbZGAuxWdpLF17MA/lH8lgUHQ5Ox7JltoWSg2oaYqVHG6xpMNkay45DDvWmr+FtpccOCYMqdFkd7gSo7ZVv0mD1XfxH0WnqBN0bb9prTzn+1T+VV/aK0H73+0z5VfoGw0nkcJq2ysy2aYs9M3aVnBA+/UdBP/aBh3qo1507aMz+Ez5VadNV8z+G35VOdPN5ij+98VG7TLT/dU/3vinqovLFb9U2/Knlet+qbflVx0u3mqf5/FBpgD+6p/n8VBstF26q5wDqbXjaCy6ewt1KnhAKUua1sEGCMjksE+EtYAimKdP8AxMby+wuJj2hal9cnWT24q1ElmwctzpKvNnY3/qSfbdMfzXn2uhZVK2kCDq2g4hTNVjvVaVVzdUrJFqaPut/NDbB6jfzUA258QZ7cV3v+j/o8s0fWtDgL1e0uIOdOmA0fvGouBPtQIPJbq14r6s8ANG8V0ZYaMQ4Wdj3tyqVP6x43nFBv0REBERAREQEREBERAREQW1aQe1zHYtc0tcM2kQfyXx5aLK6z161B32qVV9J2zlMcWn8wvsVcK8aHglZBbqtVloe2rVIq1qDbMKwY9wxN81Gxe+1dgnGdoQcztWLWnsWu1Fet/Zmjz9X/AEbf+dYNs0BddFN15sA3n0HMM5Qy+Pz7FRgNMsI9hWBWC2L9G1gSBTcRmGOg94Vnk6tzTvwz8FBh0LU5hwK2o01TcAKtFjj6zXcGT7RBH8FjeTa3NO/DPwTybV5p24fgqJXW2zn+6cP/ACD5Vbxqhzbt8fBWeTa3NO/DPwTydV5p34Z+CUX8Zoeo7fHwTjFD1DvD4KzybV5p34Z+CeTa3NO/DPwSi7jFH1TvD4KnD0fVO8PgqeTa3NO3D8E8m1ead+GfglDh6PqneHwVOHpeqe8fBV8m1ead+GfgrqejKpIBpkD1jTdA7hKUR8NS9U94+Cpw1L1T3/RbOxaAvOIqOuNuyHMoOeZkYQ+4I17dmrLN/Zejz9T/AEbP+dBqtDWNtrtVlszQf620U6To2Mc4Bx7Bj2L67jLVsHQuI+KbwTsgtrK5tFR1ei1z6VA2dtFrpaWFxdffei9MYGYOIBXblAREQEREBERAREQEREBERAXGvDpo8oWqfWZ7pi7KuNeHR9IWrrM901B4u0aaa172CmTdcWk3g3Ea4EKJ2ngBJpHfHwWstbgKtfkknhXQQ4ADHLasSo+QRBns9qo3ztPACTSMdf6Kp06AJ4Ix1/otFUqFwuAOnERM4nII6tLbkOnExOGIjV2IN6NOCJ4Ixnfw/gqN06CJFIxhjfz1bFpBaCG3IdmRPJ1RqzVKdUtbcIdOAImBydchBvG6eBEikY6/0RungcRSO/0xlmtHSrFjSwh0nAiYGBnEbUpVSwEEOxkYGPtG9jmIQbxunQZikcP8f0RunQZikcMPt/RaOlWLJwcJnUbuDs8wlKsWEuh2JkQbpiLuv2hBvG6dBJApGev9EGnhMcEZ6+fYtHSrFji+HDUZabpwEa1RtSHXyHbNRgyMdfag3vl4THBGdf2x8EOnhMcEZ6+XYtFwvKvQYjMTrnWjqhLr8O26zJxM6+xBvXadAIBpGev9FPZtLtfUbTdTc0uMA3pxgnER0LztWoXuD4dt+04F2qNZWRo3+3o6/tnWQfuOyQdT8XgHlCjHq1fduXXlyDxdn0hR6tX3bl19QEREBERAREQEREBERAREQFxfw8PpC1dZnumLtC4l4fO9I2rrM90xBzm1virWwP8Aav1dJ9qhpODS4uBj6RmprU4cJWkOnhXXSCI14yFjVDIiCqL6NVrX3iHXQQYGBw14g4KjHtDrxvQAOg4Gc8FWtVa5gaIkTjdgmczthVfWaWXcJkmbsO9hdkgtc9pfMOuwcNZxM5qtao1z7wDrpvGDicTIxJx9qCo25d2zM3cZiInJKVRoYW4ThJuyRGR2a0CvVa5wc0OAyOJ1RtOKV6jXFpaCACJGvUIO3PFUoPAaQdcQcJ2zgUovABB2z92cJnDI/VBWvVa67F7CAZ6O1LRUaWgNBBEB07TemdeGEDsVKFRovTGM6xOB2jIpSe0F07ZjCdkIK16jS260G8JknbJkbcFWrVaWXQHXscdmIEbcNRVKFQNfewI2BzZBw2hUpvaHzswiRIJGYQV4Rt2OVMTqEZZox7Q26b17CRswwz6VaXC9OyMoxnJVrPaX3sYM6xjiUFKT4gEHpAgHDWOhZtic016N1rm8o/acHTyDqgBYlcguvCYknHXip7C+a1LX9rb0MIQdQ8XJ9IUerV925diXGfFu70jQ6tX3bl2ZQEREBERAREQEREBERAREQFw7xgO9JWvrM90xdxXCfGG70nbOvT9yxB4Gs5vCVr1/+0cRdAImdqie5s8m9H+IYz2K6sW36t69N91262RrOszhsUF/29xVF9FwDSDEnNpJGM4JQe0B0xjIEgmJMyOlRkyR+eBV9YgkR0SADsETq26+1BWg9ovTGMgS0nXtHSlFzQSTG2JBIxEKlctN2IEQDAInpM7VWtBAA1gQYBxxmTgoK0Hta6TBGGDgS0+0KjC0OnAgRrBgxsIySrBaAInHEAyZzVXltyABekmYMmQMNWrD80FHOaXE4R0Axr1DoSoWl0jAY6gYE5Ksi5EC9MzBvaou5QlMtuQQL2HKh14dA2IKV3tc6RAEnBoIaPYErOaSIjWJgGNUKlEi6ROvWIJ25wlEgAgmCRBEE4TOXQECsWmIM4icDsVapBAgkxGw5yqUSBekkaxqOIOGWpWNdr9uGCCQO9vcsmyFvDUrt77R+0I+6Vhl4/QKybK5vC0rpceUZvAN2HViVR0vxaO9JUOrV905dqXEfFi70lQ6lX3Tl25QEREBERAREQEREBERAREQFwXxiz5UtnXp+5Yu9LgXjGd6UtvXp+5poPC1mgOqk3g/hJZEXYnEnblEKKm2S4vJEmZDQ6c9oW9D0vqjRhoLnFznQfvXbziekT/NVLZeSS6IHKui8SOif5rd30voNLW+yGtc4i9eulgbB1EzJnUFHdK37XK6R+ig89dKXSvQyP0UkfooPPXSl0r0Mj9FJH6KDR0sWNa5zgASQ0MDgCdZm8OhW02gOPKcG3YvXQScwW3v5rfSP0VRzkHnnsxwkiMCRdPdJVCzHC8RjBwaeiRjC9BfS+g0NYS4nlHE8p0AnpgDBS2On/WsuyROJIjYf5rc30voPW+K7/8ATodSr7py7kuFeK13pOz9Wt7py7qoCIiAiIgIiICIiAiIgIiIC+fPGS70rbevT9xTX0Gvnjxlu9LW7/Mp+4poNBeS8obyXlVTXkvKG8l5BO1/8VdfWMHKt5BkX1S+oLyXkE99VvrHvJeQZF9WueobyoXIJryXlDeS8gmvql5RXkvIPZeKl3pSz9St7py70uA+KY+lbP1K3unLvyiCIiAiIgIiICIiAiIgIiIC+c/GYfS1v/zKf/r0l9GL578bWj6lHSdpqvaRSrGnUpVINxwFJjCL2qQ5jsNeo7UHkpSVDwgzHeq8IMx3qqllLyi4QZjvThBmO9BKHKt5Q8IMx3pwgzHegmvJeUTHTqx9mKvuOyd3ILryXlbcdk7uVjnRgcDkcCglvKhcouFGY71ThBmO9BNeSVFwgzHenCDMd6CW8l5RcIMx3pwgzHeg9r4oz6Vs/Ure6cvoFcF8TNhqVNIsrta7gqVOoX1I5ALmljW3tV43pjIFd6UQREQEREBERAREQEREBERAVtSmHCHAEZESFciCDiVLm2boTiVLm2boU6IIOJUubZuhOJUubZuhTogg4lS5tm6E4lS5tm6FOiDH4jS5tm6E4jS5tm6FkIgx+I0ubZuhOI0ubZuhZCIIOJUubZuhOJUubZuhTogg4lS5tm6E4lS5tm6FOiCDiVLm2boTiVLm2boU6ILWMDRDQAMgICuREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERAREQEREBERB//Z',
              fit: BoxFit.cover,
            ),
          ),

          //LIKE, COMMENT, SHARE SECTION OF THE POST
          Row(
            spacing: 4.0,
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(
                  Icons.favorite_border_outlined,
                  color: Colors.red,
                ),
              ),
              //NUMBER OF LIKES CAN GO HERE
              DefaultTextStyle(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                child: const Text('999 likes'),
              ),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.comment_outlined),
              ),
              //NUMBER OF COMMENTS CAN GO HERE
              DefaultTextStyle(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                child: const Text('999 comments'),
              ),
              IconButton(onPressed: () {}, icon: const Icon(Icons.send)),
              //NUMBER OF SHARES CAN GO HERE
              DefaultTextStyle(
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
                child: const Text('999 shares'),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.bookmark_border),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
